import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import 'notification_service.dart';

class SlotTakenException implements Exception {
  @override
  String toString() =>
      'Sorry, that time slot was just booked. Please choose another one.';
}

/// Central app state. Listens to the signed-in user's Firestore data in real
/// time and exposes it to the UI through Provider.
///
/// Firestore structure:
///   users/{uid}                          -> profile
///   users/{uid}/pets/{petId}
///   users/{uid}/vaccinations/{id}
///   users/{uid}/appointments/{id}
///   users/{uid}/notifications/{id}
///   bookedSlots/{serviceId_yyyy-MM-dd}   -> { slots: [...] } (shared)
class AppState extends ChangeNotifier {
  AppState() {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  final List<StreamSubscription> _subs = [];
  final Set<String> _dueChecked = {};

  User? user;
  UserProfile? profile;
  List<Pet> pets = [];
  List<Vaccination> vaccinations = [];
  List<Appointment> appointments = [];
  List<AppNotification> notifications = [];
  bool authResolved = false;

  // ---------------------------------------------------------------- getters
  String get displayName =>
      profile?.firstName ??
      (user?.displayName?.split(' ').first ?? 'there');

  List<Appointment> get upcomingAppointments =>
      appointments.where((a) => a.isUpcoming).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<Appointment> get pastAppointments =>
      appointments.where((a) => a.isPast).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  List<Appointment> get cancelledAppointments =>
      appointments.where((a) => a.isCancelled).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  /// Latest record per pet+vaccine that is overdue or due within 30 days.
  List<Vaccination> get dueSoonVaccinations {
    final latest = _latestPerPetVaccine();
    final list = latest
        .where((v) =>
            v.status == VaccineStatus.dueSoon ||
            v.status == VaccineStatus.overdue)
        .toList()
      ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
    return list;
  }

  List<Vaccination> _latestPerPetVaccine() {
    final map = <String, Vaccination>{};
    for (final v in vaccinations) {
      final key = '${v.petId}|${v.vaccineName}';
      final cur = map[key];
      if (cur == null || v.dateGiven.isAfter(cur.dateGiven)) map[key] = v;
    }
    return map.values.toList();
  }

  bool isLatestRecord(Vaccination v) =>
      _latestPerPetVaccine().any((x) => x.id == v.id);

  List<AppNotification> get visibleNotifications =>
      notifications.where((n) => n.isVisible).toList();

  int get unreadCount => visibleNotifications.where((n) => !n.read).length;

  Pet? petById(String id) {
    for (final p in pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------------------------------------------------------------- auth
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(user!.uid);

  void _onAuthChanged(User? u) {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _dueChecked.clear();
    _lastStatus.clear();
    user = u;
    profile = null;
    pets = [];
    vaccinations = [];
    appointments = [];
    notifications = [];
    authResolved = true;
    if (u != null) _listen();
    notifyListeners();
  }

  void _listen() {
    _subs.add(_userDoc.snapshots().listen((doc) {
      if (doc.exists) profile = UserProfile.fromDoc(doc);
      notifyListeners();
    }, onError: _onError));

    _subs.add(_userDoc
        .collection('pets')
        .orderBy('createdAt')
        .snapshots()
        .listen((snap) {
      pets = snap.docs.map(Pet.fromDoc).toList();
      notifyListeners();
    }, onError: _onError));

    _subs.add(_userDoc
        .collection('vaccinations')
        .orderBy('dateGiven', descending: true)
        .snapshots()
        .listen((snap) {
      vaccinations = snap.docs.map(Vaccination.fromDoc).toList();
      _createDueNotifications();
      notifyListeners();
    }, onError: _onError));

    _subs.add(_userDoc
        .collection('appointments')
        .orderBy('dateTime')
        .snapshots()
        .listen((snap) {
      appointments = snap.docs.map(Appointment.fromDoc).toList();
      _detectConfirmations();
      _autoCompletePast();
      notifyListeners();
    }, onError: _onError));

    _subs.add(_userDoc
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
      notifications = snap.docs.map(AppNotification.fromDoc).toList();
      notifyListeners();
    }, onError: _onError));
  }

  void _onError(Object e) => debugPrint('Firestore listener error: $e');

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    await NotificationService.requestPermission();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await cred.user?.updateDisplayName(fullName.trim());
    await _db.collection('users').doc(cred.user!.uid).set({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'mobile': mobile.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.requestPermission();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> updateProfile(String fullName, String mobile) async {
    await _userDoc.set({
      'fullName': fullName.trim(),
      'mobile': mobile.trim(),
      'email': user?.email ?? '',
    }, SetOptions(merge: true));
    await user?.updateDisplayName(fullName.trim());
  }

  Future<void> signOut() async {
    await NotificationService.cancelAll();
    await _auth.signOut();
  }

  // ---------------------------------------------------------------- pets
  Future<void> savePet({
    String? id,
    required String name,
    required String species,
    required String breed,
    DateTime? birthdate,
    double? weight,
    required String gender,
    String? photoBase64,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'species': species,
      'breed': breed,
      'birthdate': birthdate == null ? null : Timestamp.fromDate(birthdate),
      'weight': weight,
      'gender': gender,
      'photoBase64': photoBase64,
    };
    final col = _userDoc.collection('pets');
    if (id == null) {
      data['notes'] = '';
      data['createdAt'] = FieldValue.serverTimestamp();
      await col.add(data);
      await _addNotification(
        title: 'Pet added',
        body: '${name.trim()} was added to your pets.',
        type: 'pet',
      );
    } else {
      await col.doc(id).update(data);
      // keep the pet name in related records in sync
      final batch = _db.batch();
      for (final v in vaccinations.where((v) => v.petId == id)) {
        batch.update(_userDoc.collection('vaccinations').doc(v.id),
            {'petName': name.trim()});
      }
      for (final a in appointments.where((a) => a.petId == id)) {
        batch.update(_userDoc.collection('appointments').doc(a.id),
            {'petName': name.trim()});
      }
      await batch.commit();
    }
  }

  Future<void> updatePetNotes(String petId, String notes) =>
      _userDoc.collection('pets').doc(petId).update({'notes': notes});

  /// Deletes a pet together with its vaccinations, and cancels its
  /// upcoming appointments (freeing their time slots).
  Future<void> deletePet(Pet pet) async {
    for (final a in appointments.where((a) => a.petId == pet.id && a.isUpcoming)) {
      await cancelAppointment(a, silent: true);
    }
    final batch = _db.batch();
    for (final v in vaccinations.where((v) => v.petId == pet.id)) {
      batch.delete(_userDoc.collection('vaccinations').doc(v.id));
      NotificationService.cancel('vac_${v.id}');
    }
    for (final a in appointments.where((a) => a.petId == pet.id)) {
      batch.delete(_userDoc.collection('appointments').doc(a.id));
    }
    batch.delete(_userDoc.collection('pets').doc(pet.id));
    await batch.commit();
  }

  // ---------------------------------------------------------------- vaccines
  Future<void> saveVaccination({
    String? id,
    required Pet pet,
    required String vaccineName,
    required DateTime dateGiven,
    DateTime? nextDueDate,
    required String clinic,
    required bool remind,
  }) async {
    final data = <String, dynamic>{
      'petId': pet.id,
      'petName': pet.name,
      'vaccineName': vaccineName.trim(),
      'dateGiven': Timestamp.fromDate(dateGiven),
      'nextDueDate':
          nextDueDate == null ? null : Timestamp.fromDate(nextDueDate),
      'clinic': clinic.trim(),
      'remind': remind,
    };
    final col = _userDoc.collection('vaccinations');
    String docId;
    if (id == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await col.add(data);
      docId = ref.id;
      await _addNotification(
        title: 'Vaccination recorded',
        body: '${vaccineName.trim()} added to ${pet.name}\'s records.',
        type: 'vaccine',
      );
    } else {
      docId = id;
      await col.doc(id).update(data);
    }

    // Device reminder: 3 days before the due date at 9:00 AM.
    await NotificationService.cancel('vac_$docId');
    if (remind && nextDueDate != null) {
      final when = DateTime(
          nextDueDate.year, nextDueDate.month, nextDueDate.day - 3, 9);
      await NotificationService.schedule(
        key: 'vac_$docId',
        title: 'Vaccine due in 3 days',
        body:
            '${pet.name}\'s ${vaccineName.trim()} is due on ${DateFormat('MMM d').format(nextDueDate)}.',
        when: when,
      );
    }
  }

  Future<void> deleteVaccination(Vaccination v) async {
    await NotificationService.cancel('vac_${v.id}');
    await _userDoc.collection('vaccinations').doc(v.id).delete();
  }

  /// Creates an in-app "Vaccine due" notification once per record/due date.
  Future<void> _createDueNotifications() async {
    for (final v in dueSoonVaccinations) {
      final days = v.daysUntilDue!;
      if (days > 14) continue;
      final key =
          'due_${v.id}_${DateFormat('yyyyMMdd').format(v.nextDueDate!)}';
      if (_dueChecked.contains(key)) continue;
      _dueChecked.add(key);
      try {
        final ref = _userDoc.collection('notifications').doc(key);
        final existing = await ref.get();
        if (existing.exists) continue;
        await ref.set({
          'title': days < 0
              ? 'Vaccine overdue'
              : days == 0
                  ? 'Vaccine due today'
                  : 'Vaccine due in $days day${days == 1 ? '' : 's'}',
          'body':
              '${v.petName}\'s ${v.vaccineName} is due ${DateFormat('MMM d').format(v.nextDueDate!)}.',
          'type': 'vaccine',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'showAt': Timestamp.now(),
        });
      } catch (e) {
        debugPrint('Due notification failed: $e');
      }
    }
  }

  // ---------------------------------------------------------------- bookings
  static String dateKeyOf(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime combine(DateTime date, String slot) {
    final t = DateFormat('h:mm a', 'en_US').parse(slot);
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
  }

  DocumentReference<Map<String, dynamic>> _slotDoc(
          String serviceId, String dateKey) =>
      _db.collection('bookedSlots').doc('${serviceId}_$dateKey');

  /// Live list of slots already booked for a service on a given day.
  Stream<List<String>> bookedSlots(String serviceId, DateTime date) {
    return _slotDoc(serviceId, dateKeyOf(date)).snapshots().map((doc) {
      final raw = doc.data()?['slots'];
      return raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
    });
  }

  String _newBookingId() {
    final r = Random();
    final n = (DateTime.now().millisecondsSinceEpoch % 100000 + r.nextInt(1000)) % 100000;
    return 'PCH-${DateTime.now().year}-${n.toString().padLeft(5, '0')}';
  }

  Future<Appointment> bookAppointment({
    required Pet pet,
    required PetService service,
    required DateTime date,
    required String slot,
    required String notes,
    required bool remind,
  }) async {
    final dateTime = combine(date, slot);
    final dateKey = dateKeyOf(date);
    final apptRef = _userDoc.collection('appointments').doc();
    final slotRef = _slotDoc(service.id, dateKey);
    final bookingId = _newBookingId();

    await _db.runTransaction((tx) async {
      final slotSnap = await tx.get(slotRef);
      final taken = List<String>.from(
          (slotSnap.data()?['slots'] as List?)?.map((e) => e.toString()) ??
              const <String>[]);
      if (taken.contains(slot)) throw SlotTakenException();
      taken.add(slot);
      tx.set(slotRef, {'slots': taken}, SetOptions(merge: true));
      tx.set(apptRef, {
        'bookingId': bookingId,
        'petId': pet.id,
        'petName': pet.name,
        'serviceId': service.id,
        'serviceName': service.name,
        'provider': service.provider,
        'dateTime': Timestamp.fromDate(dateTime),
        'slot': slot,
        'dateKey': dateKey,
        'notes': notes.trim(),
        'remind': remind,
        'price': service.price,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    final when = DateFormat('MMM d').format(dateTime);
    await _addNotification(
      title: 'Booking received',
      body: '${service.name} for ${pet.name} on $when is pending confirmation.',
      type: 'booking',
    );
    await NotificationService.showNow(apptRef.id, 'Booking received',
        '${service.name} for ${pet.name} on $when at $slot.');
    await _scheduleAppointmentReminder(
        apptRef.id, pet.name, service.name, service.provider, dateTime, slot, remind);

    return Appointment(
      id: apptRef.id,
      bookingId: bookingId,
      petId: pet.id,
      petName: pet.name,
      serviceId: service.id,
      serviceName: service.name,
      provider: service.provider,
      dateTime: dateTime,
      slot: slot,
      dateKey: dateKey,
      notes: notes,
      remind: remind,
      price: service.price,
      status: 'pending',
    );
  }

  Future<Appointment> rescheduleAppointment({
    required Appointment appt,
    required DateTime date,
    required String slot,
    required String notes,
    required bool remind,
  }) async {
    final dateTime = combine(date, slot);
    final newKey = dateKeyOf(date);
    final oldRef = _slotDoc(appt.serviceId, appt.dateKey);
    final newRef = _slotDoc(appt.serviceId, newKey);
    final apptRef = _userDoc.collection('appointments').doc(appt.id);
    final sameDay = newKey == appt.dateKey;

    await _db.runTransaction((tx) async {
      final newSnap = await tx.get(newRef);
      final newSlots = List<String>.from(
          (newSnap.data()?['slots'] as List?)?.map((e) => e.toString()) ??
              const <String>[]);
      List<String> oldSlots = newSlots;
      if (!sameDay) {
        final oldSnap = await tx.get(oldRef);
        oldSlots = List<String>.from(
            (oldSnap.data()?['slots'] as List?)?.map((e) => e.toString()) ??
                const <String>[]);
      }
      final isOwnSlot = sameDay && slot == appt.slot;
      if (!isOwnSlot && newSlots.contains(slot)) throw SlotTakenException();

      if (sameDay) {
        newSlots.remove(appt.slot);
        newSlots.add(slot);
        tx.set(newRef, {'slots': newSlots}, SetOptions(merge: true));
      } else {
        oldSlots.remove(appt.slot);
        newSlots.add(slot);
        tx.set(oldRef, {'slots': oldSlots}, SetOptions(merge: true));
        tx.set(newRef, {'slots': newSlots}, SetOptions(merge: true));
      }
      tx.update(apptRef, {
        'dateTime': Timestamp.fromDate(dateTime),
        'slot': slot,
        'dateKey': newKey,
        'notes': notes.trim(),
        'remind': remind,
        'status': 'pending',
      });
    });

    await _addNotification(
      title: 'Appointment rescheduled',
      body:
          '${appt.serviceName} for ${appt.petName} moved to ${DateFormat('MMM d').format(dateTime)} at $slot.',
      type: 'booking',
    );
    await _scheduleAppointmentReminder(appt.id, appt.petName, appt.serviceName,
        appt.provider, dateTime, slot, remind);

    return Appointment(
      id: appt.id,
      bookingId: appt.bookingId,
      petId: appt.petId,
      petName: appt.petName,
      serviceId: appt.serviceId,
      serviceName: appt.serviceName,
      provider: appt.provider,
      dateTime: dateTime,
      slot: slot,
      dateKey: newKey,
      notes: notes,
      remind: remind,
      price: appt.price,
      status: 'pending',
    );
  }

  Future<void> cancelAppointment(Appointment appt, {bool silent = false}) async {
    final batch = _db.batch();
    batch.update(_userDoc.collection('appointments').doc(appt.id),
        {'status': 'cancelled'});
    batch.set(
      _slotDoc(appt.serviceId, appt.dateKey),
      {
        'slots': FieldValue.arrayRemove([appt.slot])
      },
      SetOptions(merge: true),
    );
    batch.delete(_userDoc.collection('notifications').doc('rem_${appt.id}'));
    await batch.commit();
    await NotificationService.cancel('appt_${appt.id}');
    if (!silent) {
      await _addNotification(
        title: 'Appointment cancelled',
        body:
            '${appt.serviceName} for ${appt.petName} on ${DateFormat('MMM d').format(appt.dateTime)} was cancelled.',
        type: 'cancel',
      );
    }
  }

  Future<void> _scheduleAppointmentReminder(String apptId, String petName,
      String serviceName, String provider, DateTime dateTime, String slot,
      bool remind) async {
    await NotificationService.cancel('appt_$apptId');
    final remRef = _userDoc.collection('notifications').doc('rem_$apptId');
    final when = dateTime.subtract(const Duration(days: 1));
    if (!remind || !when.isAfter(DateTime.now())) {
      await remRef.delete(); // no-op if it doesn't exist
      return;
    }
    final title = 'Reminder: $petName\'s ${serviceName.toLowerCase()} tomorrow';
    final body = '${DateFormat('MMM d').format(dateTime)} · $slot · $provider';
    await NotificationService.schedule(
        key: 'appt_$apptId', title: title, body: body, when: when);
    // In-app copy that becomes visible at reminder time.
    await remRef.set({
      'title': title,
      'body': body,
      'type': 'reminder',
      'read': false,
      'createdAt': Timestamp.fromDate(when),
      'showAt': Timestamp.fromDate(when),
    });
  }

  final Map<String, String> _lastStatus = {};

  /// When a clinic (or you, in the Firebase console) changes an appointment's
  /// status to "confirmed", tell the user.
  void _detectConfirmations() {
    final first = _lastStatus.isEmpty;
    for (final a in appointments) {
      final prev = _lastStatus[a.id];
      _lastStatus[a.id] = a.status;
      if (first || prev == null) continue;
      if (prev != 'confirmed' && a.status == 'confirmed') {
        final when = DateFormat('MMM d').format(a.dateTime);
        _addNotification(
          title: 'Appointment confirmed',
          body: '${a.provider} confirmed ${a.petName}\'s $when visit.',
          type: 'confirmed',
        );
        NotificationService.showNow('conf_${a.id}', 'Appointment confirmed',
            '${a.provider} confirmed ${a.petName}\'s $when visit.');
      }
    }
  }

  /// Marks past pending/confirmed appointments as completed.
  Future<void> _autoCompletePast() async {
    final now = DateTime.now();
    for (final a in appointments) {
      if ((a.status == 'pending' || a.status == 'confirmed') &&
          a.dateTime.add(const Duration(hours: 2)).isBefore(now)) {
        try {
          await _userDoc
              .collection('appointments')
              .doc(a.id)
              .update({'status': 'completed'});
        } catch (_) {}
      }
    }
  }

  // ---------------------------------------------------------------- notifs
  Future<void> _addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _userDoc.collection('notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'showAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Add notification failed: $e');
    }
  }

  Future<void> markRead(AppNotification n) =>
      _userDoc.collection('notifications').doc(n.id).update({'read': true});

  Future<void> markAllRead() async {
    final batch = _db.batch();
    for (final n in visibleNotifications.where((n) => !n.read)) {
      batch.update(_userDoc.collection('notifications').doc(n.id), {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(AppNotification n) {
    // remove locally first so a swiped (Dismissible) tile leaves the tree now
    notifications = notifications.where((x) => x.id != n.id).toList();
    notifyListeners();
    return _userDoc.collection('notifications').doc(n.id).delete();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _toDate(dynamic v, [DateTime? fallback]) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return fallback ?? DateTime.now();
}

DateTime? _toDateOrNull(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return null;
}

/// ---------------- User profile ----------------
class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String mobile;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.mobile,
  });

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      fullName: (d['fullName'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      mobile: (d['mobile'] ?? '') as String,
    );
  }
}

/// ---------------- Pet ----------------
class Pet {
  final String id;
  final String name;
  final String species;
  final String breed;
  final DateTime? birthdate;
  final double? weight;
  final String gender;
  final String? photoBase64;
  final String notes;
  final DateTime createdAt;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.birthdate,
    required this.weight,
    required this.gender,
    required this.photoBase64,
    required this.notes,
    required this.createdAt,
  });

  /// Decoded photo bytes (decoded once and cached).
  late final Uint8List? photoBytes =
      (photoBase64 == null || photoBase64!.isEmpty) ? null : base64Decode(photoBase64!);

  String get ageLabel {
    if (birthdate == null) return '—';
    final now = DateTime.now();
    int months = (now.year - birthdate!.year) * 12 + now.month - birthdate!.month;
    if (now.day < birthdate!.day) months--;
    if (months < 0) months = 0;
    if (months < 12) return '$months mo${months == 1 ? '' : 's'}';
    final years = months ~/ 12;
    return '$years yr${years == 1 ? '' : 's'}';
  }

  String get weightLabel {
    if (weight == null) return '—';
    final w = weight!;
    return '${w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1)} kg';
  }

  String get speciesBreed => breed.isEmpty ? species : '$species · $breed';

  /// Default picture asset based on species, used when no photo uploaded.
  String get defaultAsset {
    switch (species.toLowerCase()) {
      case 'dog':
        return 'assets/images/pet_dog.png';
      case 'cat':
        return 'assets/images/pet_cat.png';
      case 'rabbit':
        return 'assets/images/pet_rabbit.png';
      case 'bird':
        return 'assets/images/pet_bird.png';
      default:
        return 'assets/images/pet_other.png';
    }
  }

  factory Pet.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Pet(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      species: (d['species'] ?? 'Dog') as String,
      breed: (d['breed'] ?? '') as String,
      birthdate: _toDateOrNull(d['birthdate']),
      weight: (d['weight'] as num?)?.toDouble(),
      gender: (d['gender'] ?? 'Male') as String,
      photoBase64: d['photoBase64'] as String?,
      notes: (d['notes'] ?? '') as String,
      createdAt: _toDate(d['createdAt']),
    );
  }
}

/// ---------------- Vaccination ----------------
enum VaccineStatus { overdue, dueSoon, upToDate, noDueDate }

class Vaccination {
  final String id;
  final String petId;
  final String petName;
  final String vaccineName;
  final DateTime dateGiven;
  final DateTime? nextDueDate;
  final String clinic;
  final bool remind;

  Vaccination({
    required this.id,
    required this.petId,
    required this.petName,
    required this.vaccineName,
    required this.dateGiven,
    required this.nextDueDate,
    required this.clinic,
    required this.remind,
  });

  /// Whole days until the next due date (negative if overdue).
  int? get daysUntilDue {
    if (nextDueDate == null) return null;
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(nextDueDate!.year, nextDueDate!.month, nextDueDate!.day);
    return b.difference(a).inDays;
  }

  VaccineStatus get status {
    final d = daysUntilDue;
    if (d == null) return VaccineStatus.noDueDate;
    if (d < 0) return VaccineStatus.overdue;
    if (d <= 30) return VaccineStatus.dueSoon;
    return VaccineStatus.upToDate;
  }

  factory Vaccination.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Vaccination(
      id: doc.id,
      petId: (d['petId'] ?? '') as String,
      petName: (d['petName'] ?? '') as String,
      vaccineName: (d['vaccineName'] ?? '') as String,
      dateGiven: _toDate(d['dateGiven']),
      nextDueDate: _toDateOrNull(d['nextDueDate']),
      clinic: (d['clinic'] ?? '') as String,
      remind: (d['remind'] ?? false) as bool,
    );
  }
}

/// ---------------- Appointment ----------------
class Appointment {
  final String id;
  final String bookingId;
  final String petId;
  final String petName;
  final String serviceId;
  final String serviceName;
  final String provider;
  final DateTime dateTime;
  final String slot;
  final String dateKey;
  final String notes;
  final bool remind;
  final double price;
  final String status; // pending | confirmed | completed | cancelled

  Appointment({
    required this.id,
    required this.bookingId,
    required this.petId,
    required this.petName,
    required this.serviceId,
    required this.serviceName,
    required this.provider,
    required this.dateTime,
    required this.slot,
    required this.dateKey,
    required this.notes,
    required this.remind,
    required this.price,
    required this.status,
  });

  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming =>
      !isCancelled && status != 'completed' && dateTime.isAfter(DateTime.now());
  bool get isPast => !isCancelled && !isUpcoming;

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Appointment(
      id: doc.id,
      bookingId: (d['bookingId'] ?? '') as String,
      petId: (d['petId'] ?? '') as String,
      petName: (d['petName'] ?? '') as String,
      serviceId: (d['serviceId'] ?? '') as String,
      serviceName: (d['serviceName'] ?? '') as String,
      provider: (d['provider'] ?? '') as String,
      dateTime: _toDate(d['dateTime']),
      slot: (d['slot'] ?? '') as String,
      dateKey: (d['dateKey'] ?? '') as String,
      notes: (d['notes'] ?? '') as String,
      remind: (d['remind'] ?? false) as bool,
      price: ((d['price'] ?? 0) as num).toDouble(),
      status: (d['status'] ?? 'pending') as String,
    );
  }
}

/// ---------------- In-app notification ----------------
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // vaccine | booking | confirmed | reminder | cancel | pet
  final DateTime createdAt;
  final DateTime showAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.showAt,
    required this.read,
  });

  bool get isVisible => !showAt.isAfter(DateTime.now());

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final created = _toDate(d['createdAt']);
    return AppNotification(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      body: (d['body'] ?? '') as String,
      type: (d['type'] ?? 'booking') as String,
      createdAt: created,
      showAt: _toDate(d['showAt'], created),
      read: (d['read'] ?? false) as bool,
    );
  }
}

/// ---------------- Service (catalog item) ----------------
class PetService {
  final String id;
  final String name;
  final String category;
  final String provider;
  final String location;
  final double price;
  final String priceLabel;
  final String duration;
  final double rating;
  final int reviews;
  final String image;
  final String description;
  final List<String> includes;
  final String hours;
  final String phone;

  const PetService({
    required this.id,
    required this.name,
    required this.category,
    required this.provider,
    required this.location,
    required this.price,
    required this.priceLabel,
    required this.duration,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.description,
    required this.includes,
    required this.hours,
    required this.phone,
  });
}

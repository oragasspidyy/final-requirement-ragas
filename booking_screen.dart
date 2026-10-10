import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/catalog.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../pets/add_pet_screen.dart';
import 'booking_success_screen.dart';

/// Book a new appointment, or reschedule [reschedule].
class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    this.initialPetId,
    this.initialServiceId,
    this.reschedule,
  });
  final String? initialPetId;
  final String? initialServiceId;
  final Appointment? reschedule;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _petId;
  String? _serviceId;
  late DateTime _date;
  String? _slot;
  final _notes = TextEditingController();
  bool _remind = true;
  bool _saving = false;

  late final DateTime _firstDay;
  late final DateTime _lastDay;

  bool get _isReschedule => widget.reschedule != null;

  static bool _selectable(DateTime d) => d.weekday != DateTime.sunday;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day);
    // if every slot today has passed, start from tomorrow
    final lastSlotToday = AppState.combine(first, timeSlots.last);
    if (!lastSlotToday.isAfter(now)) first = first.add(const Duration(days: 1));
    while (!_selectable(first)) {
      first = first.add(const Duration(days: 1));
    }
    _firstDay = first;
    _lastDay = first.add(const Duration(days: 90));
    _date = _firstDay;

    final r = widget.reschedule;
    if (r != null) {
      _petId = r.petId;
      _serviceId = r.serviceId;
      final d = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
      if (!d.isBefore(_firstDay) && !d.isAfter(_lastDay) && _selectable(d)) {
        _date = d;
        _slot = r.slot;
      }
      _notes.text = r.notes;
      _remind = r.remind;
    } else {
      _petId = widget.initialPetId;
      _serviceId = widget.initialServiceId;
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Stream<List<String>>? _slotStream;
  String? _slotStreamKey;

  /// Cached live stream of booked slots for the chosen service + date.
  Stream<List<String>> _bookedFor(AppState s, String serviceId) {
    final key = '${serviceId}_${AppState.dateKeyOf(_date)}';
    if (_slotStream == null || _slotStreamKey != key) {
      _slotStreamKey = key;
      _slotStream = s.bookedSlots(serviceId, _date);
    }
    return _slotStream!;
  }

  PetService? get _service => _serviceId == null ? null : serviceById(_serviceId!);

  bool _slotDisabled(String slot, List<String> booked) {
    final dt = AppState.combine(_date, slot);
    if (!dt.isAfter(DateTime.now().add(const Duration(minutes: 30)))) return true;
    final r = widget.reschedule;
    final isOwn = r != null &&
        r.serviceId == _serviceId &&
        r.dateKey == AppState.dateKeyOf(_date) &&
        r.slot == slot;
    return booked.contains(slot) && !isOwn;
  }

  Future<void> _review(Pet pet) async {
    final service = _service;
    if (service == null) {
      showSnack(context, 'Please choose a service', error: true);
      return;
    }
    if (_slot == null) {
      showSnack(context, 'Please choose a time slot', error: true);
      return;
    }
    final dt = AppState.combine(_date, _slot!);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isReschedule ? 'Confirm new schedule' : 'Confirm your booking',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoRow('Pet', pet.name),
              InfoRow('Service', service.name),
              InfoRow('Provider', service.provider),
              InfoRow('Date & time', '${DateFormat('EEE, MMM d').format(dt)} · $_slot'),
              InfoRow('Reminder', _remind ? '1 day before' : 'Off'),
              InfoRow('Estimated total', peso.format(service.price), last: true),
              const SizedBox(height: 10),
              const Text(
                'Payment is made at the clinic. You can cancel up to 24 hours before the appointment.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      final Appointment appt;
      if (_isReschedule) {
        appt = await state.rescheduleAppointment(
          appt: widget.reschedule!,
          date: _date,
          slot: _slot!,
          notes: _notes.text,
          remind: _remind,
        );
      } else {
        appt = await state.bookAppointment(
          pet: pet,
          service: service,
          date: _date,
          slot: _slot!,
          notes: _notes.text,
          remind: _remind,
        );
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(appt: appt, rescheduled: _isReschedule),
        ),
      );
    } on SlotTakenException catch (e) {
      if (mounted) {
        setState(() => _slot = null);
        showSnack(context, e.toString(), error: true);
      }
    } on FirebaseException catch (e) {
      if (mounted) showSnack(context, e.message ?? 'Booking failed', error: true);
    } catch (e) {
      final msg = e.toString().contains('time slot')
          ? SlotTakenException().toString()
          : 'Booking failed: $e';
      if (mounted) showSnack(context, msg, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pets = s.pets;
    if (_petId != null && s.petById(_petId!) == null && pets.isNotEmpty) _petId = null;
    _petId ??= pets.length == 1 ? pets.first.id : null;
    final pet = _petId == null ? null : s.petById(_petId!);
    final service = _service;

    final step1 = pet != null;
    final step2 = service != null;
    final step3 = _slot != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(_isReschedule ? 'Reschedule' : 'Book Appointment')),
      body: pets.isEmpty
          ? EmptyState(
              icon: Icons.pets,
              title: 'Add a pet first',
              message: 'You need at least one pet profile to book an appointment.',
              action: FilledButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddPetScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Add Pet'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                // ---- steps
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Step('1 Pet', step1),
                    const _Dash(),
                    _Step('2 Service', step2),
                    const _Dash(),
                    _Step('3 Schedule', step3),
                    const _Dash(),
                    _Step('4 Review', false),
                  ],
                ),
                ),

                // ---- pet
                const FieldLabel('Select pet *'),
                SizedBox(
                  height: 108,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in pets)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _PetChoice(
                            pet: p,
                            selected: p.id == _petId,
                            onTap: _isReschedule ? null : () => setState(() => _petId = p.id),
                          ),
                        ),
                    ],
                  ),
                ),

                // ---- service
                const FieldLabel('Service *'),
                AppDropdown<String>(
                  value: _serviceId,
                  items: serviceCatalog.map((e) => e.id).toList(),
                  hint: 'Choose a service',
                  labelOf: (id) {
                    final sv = serviceById(id)!;
                    return '${sv.name} – ${sv.provider} (${sv.priceLabel} · ${sv.duration})';
                  },
                  onChanged: _isReschedule
                      ? null
                      : (v) => setState(() {
                            _serviceId = v;
                            _slot = null;
                          }),
                ),

                // ---- date
                const FieldLabel('Date *'),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _date,
                    firstDate: _firstDay,
                    lastDate: _lastDay,
                    selectableDayPredicate: _selectable,
                    onDateChanged: (d) => setState(() {
                      _date = DateTime(d.year, d.month, d.day);
                      _slot = null;
                    }),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Clinics are closed on Sundays.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ),

                // ---- time slots
                const FieldLabel('Available time slots *'),
                if (service == null)
                  const Text('Choose a service to see available times.',
                      style: TextStyle(color: AppColors.muted))
                else
                  StreamBuilder<List<String>>(
                    stream: _bookedFor(s, service.id),
                    builder: (context, snap) {
                      final booked = snap.data ?? const <String>[];
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in timeSlots)
                            _SlotChip(
                              label: t,
                              selected: _slot == t,
                              disabled: _slotDisabled(t, booked),
                              onTap: () => setState(() => _slot = t),
                            ),
                        ],
                      );
                    },
                  ),

                // ---- notes
                const FieldLabel('Notes for the provider (optional)'),
                TextField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'e.g. ${pet?.name ?? 'My pet'} is nervous around dryers…',
                  ),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.warning),
                  title: const Text('Remind me 1 day before'),
                  value: _remind,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _remind = v),
                ),

                // ---- summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          pet?.name ?? 'No pet',
                          service?.name ?? 'No service',
                          DateFormat('EEE, MMM d').format(_date),
                          _slot ?? 'No time',
                        ].join(' · '),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Estimated total',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                          Text(service == null ? '—' : peso.format(service.price),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          if (pet == null) {
                            showSnack(context, 'Please select a pet', error: true);
                            return;
                          }
                          _review(pet);
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(_isReschedule ? 'Review & Reschedule' : 'Review & Confirm Booking'),
                ),
              ],
            ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.label, this.done);
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: done ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: done ? AppColors.primary : AppColors.border),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: done ? Colors.white : AppColors.ink)),
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash();
  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.border,
      );
}

class _PetChoice extends StatelessWidget {
  const _PetChoice({required this.pet, required this.selected, required this.onTap});
  final Pet pet;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.primaryLight : Colors.transparent,
          border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            PetAvatar(pet: pet, size: 62),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(pet.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
                ),
                if (selected)
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : disabled
                  ? const Color(0xFFF3F4F6)
                  : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : disabled
                    ? const Color(0xFFD1D5DB)
                    : AppColors.ink,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : disabled
                    ? const Color(0xFF9CA3AF)
                    : AppColors.ink,
            decoration: disabled ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

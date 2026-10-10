import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../booking/booking_screen.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appt, this.compact = false});
  final Appointment appt;
  final bool compact;

  bool get _within24h =>
      appt.dateTime.difference(DateTime.now()) < const Duration(hours: 24);

  Future<void> _cancel(BuildContext context) async {
    if (_within24h) {
      showSnack(context,
          'Appointments can only be cancelled up to 24 hours before. Please call the clinic.',
          error: true);
      return;
    }
    final state = context.read<AppState>();
    final ok = await confirmDialog(
      context,
      title: 'Cancel appointment?',
      message:
          '${appt.serviceName} for ${appt.petName} on ${fmtDay(appt.dateTime)} at ${appt.slot} will be cancelled.',
      confirmText: 'Cancel appointment',
      destructive: true,
    );
    if (!ok) return;
    try {
      await state.cancelAppointment(appt);
      if (context.mounted) showSnack(context, 'Appointment cancelled');
    } on FirebaseException catch (e) {
      if (context.mounted) showSnack(context, e.message ?? 'Failed to cancel', error: true);
    }
  }

  void _reschedule(BuildContext context) {
    if (_within24h) {
      showSnack(context,
          'Appointments can only be rescheduled up to 24 hours before. Please call the clinic.',
          error: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingScreen(reschedule: appt)),
    );
  }

  void _details(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${appt.serviceName} – ${appt.petName}',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            InfoRow('Booking ID', appt.bookingId),
            InfoRow('Provider', appt.provider),
            InfoRow('Date & time', '${fmtDay(appt.dateTime)} · ${appt.slot}'),
            InfoRow('Estimated total', peso.format(appt.price)),
            InfoRow('Reminder', appt.remind ? '1 day before' : 'Off'),
            InfoRow('Status', '', trailing: StatusChip(appt.status), last: appt.notes.isEmpty),
            if (appt.notes.isNotEmpty) InfoRow('Notes', appt.notes, last: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = context.select<AppState, Pet?>((s) => s.petById(appt.petId));
    final showActions = !compact && appt.isUpcoming;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _details(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  PetAvatar(pet: pet, size: 54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${appt.serviceName} – ${appt.petName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('${fmtDay(appt.dateTime)} · ${appt.slot}',
                            style: const TextStyle(color: AppColors.muted)),
                        Text(appt.provider,
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusChip(appt.status),
                ],
              ),
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reschedule(context),
                        child: const Text('Reschedule'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger, width: 1.5),
                        ),
                        onPressed: () => _cancel(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../home_shell.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.appt, this.rescheduled = false});
  final Appointment appt;
  final bool rescheduled;

  @override
  Widget build(BuildContext context) {
    final remindAt = appt.dateTime.subtract(const Duration(days: 1));
    final showReminder = appt.remind && remindAt.isAfter(DateTime.now());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goToTab(context, 0);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.4, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) => Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 80, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(rescheduled ? 'Appointment Rescheduled!' : 'Appointment Booked!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Booking ID: ${appt.bookingId}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 22),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(
                        children: [
                          InfoRow('Pet', appt.petName),
                          InfoRow('Service', appt.serviceName),
                          InfoRow('Provider', appt.provider),
                          InfoRow('When',
                              '${DateFormat('MMM d, y').format(appt.dateTime)} · ${appt.slot}'),
                          InfoRow('Status', '',
                              trailing: const StatusChip('pending'), last: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (showReminder)
                    Text(
                      '🔔 We\'ll remind you on ${DateFormat('MMM d').format(remindAt)} at ${DateFormat('h:mm a').format(remindAt)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  const SizedBox(height: 26),
                  ElevatedButton(
                    onPressed: () => goToTab(context, 3),
                    child: const Text('View My Appointments'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    onPressed: () => goToTab(context, 0),
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

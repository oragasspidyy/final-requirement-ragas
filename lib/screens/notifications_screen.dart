import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.visibleNotifications;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final today = list.where((n) => !n.showAt.isBefore(startOfToday)).toList();
    final earlier = list.where((n) => n.showAt.isBefore(startOfToday)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: s.unreadCount == 0
                ? null
                : () async {
                    await s.markAllRead();
                    if (context.mounted) showSnack(context, 'All marked as read');
                  },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: list.isEmpty
          ? const Center(
              child: EmptyState(
                icon: Icons.notifications_none,
                title: 'You\'re all caught up',
                message: 'Booking updates and vaccine reminders will show here.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (today.isNotEmpty) ...[
                  const SectionHeader('Today'),
                  for (final n in today) _NotifTile(n: n),
                ],
                if (earlier.isNotEmpty) ...[
                  const SectionHeader('Earlier'),
                  for (final n in earlier) _NotifTile(n: n),
                ],
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Swipe a notification to remove it',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ),
              ],
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.n});
  final AppNotification n;

  (IconData, Color) get _icon {
    switch (n.type) {
      case 'vaccine':
        return (Icons.vaccines, const Color(0xFF2563EB));
      case 'reminder':
        return (Icons.alarm, AppColors.warning);
      case 'confirmed':
        return (Icons.check_circle, AppColors.success);
      case 'cancel':
        return (Icons.event_busy, AppColors.danger);
      case 'pet':
        return (Icons.pets, AppColors.accent);
      default:
        return (Icons.calendar_month, AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _icon;
    final state = context.read<AppState>();
    final now = DateTime.now();
    final sameDay = n.showAt.year == now.year &&
        n.showAt.month == now.month &&
        n.showAt.day == now.day;
    final time = sameDay
        ? DateFormat('h:mm a').format(n.showAt)
        : DateFormat('MMM d · h:mm a').format(n.showAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(n.id),
        onDismissed: (_) => state.deleteNotification(n),
        background: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline, color: AppColors.danger),
        ),
        child: Card(
          color: n.read ? Colors.white : const Color(0xFFF0FDFA),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: n.read ? null : () => state.markRead(n),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title,
                            style: TextStyle(
                                fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                                fontSize: 15.5)),
                        const SizedBox(height: 2),
                        Text(n.body, style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Text(time,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!n.read)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
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

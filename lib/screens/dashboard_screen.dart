import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'appointments/appointment_card.dart';
import 'booking/booking_screen.dart';
import 'home_shell.dart';
import 'notifications_screen.dart';
import 'pets/add_pet_screen.dart';
import 'pets/pet_profile_screen.dart';
import 'profile_screen.dart';
import 'vaccines/add_vaccine_screen.dart';
import 'vaccines/vaccinations_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final upcoming = s.upcomingAppointments;
    final due = s.dueSoonVaccinations;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('PetCareHub'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _push(context, const NotificationsScreen()),
            icon: Badge(
              isLabelVisible: s.unreadCount > 0,
              label: Text('${s.unreadCount}'),
              child: const Icon(Icons.notifications_none_rounded, size: 28),
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => _push(context, const ProfileScreen()),
            icon: const Icon(Icons.account_circle_outlined, size: 28),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('${_greeting()}, ${s.displayName}!',
              style: const TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
              style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 16),

          // ---- stats
          Row(
            children: [
              _StatCard(
                  value: s.pets.length,
                  label: 'My Pets',
                  icon: Icons.pets,
                  onTap: () => shellTab.value = 1),
              const SizedBox(width: 10),
              _StatCard(
                  value: upcoming.length,
                  label: 'Upcoming\nAppointments',
                  icon: Icons.event_available,
                  onTap: () => shellTab.value = 3),
              const SizedBox(width: 10),
              _StatCard(
                  value: due.length,
                  label: 'Vaccine\nDue Soon',
                  icon: Icons.vaccines_outlined,
                  onTap: () => _push(context, const VaccinationsScreen())),
            ],
          ),

          // ---- reminder banner
          if (due.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReminderBanner(
              v: due.first,
              onView: () => _push(context, const VaccinationsScreen()),
            ),
          ],

          // ---- pets
          SectionHeader('My Pets', onSeeAll: () => shellTab.value = 1),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in s.pets)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GestureDetector(
                      onTap: () => _push(context, PetProfileScreen(petId: p.id)),
                      child: Column(
                        children: [
                          PetAvatar(pet: p, size: 74),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 78,
                            child: Text(p.name,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => _push(context, const AddPetScreen()),
                  child: Column(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight,
                          border: Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: const Icon(Icons.add, color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 6),
                      const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---- upcoming appointments
          SectionHeader('Upcoming Appointments', onSeeAll: () => shellTab.value = 3),
          if (upcoming.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_outlined, color: AppColors.muted),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text('No upcoming appointments yet.',
                            style: TextStyle(color: AppColors.muted))),
                    TextButton(
                        onPressed: () => _push(context, const BookingScreen()),
                        child: const Text('Book now')),
                  ],
                ),
              ),
            )
          else
            for (final a in upcoming.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppointmentCard(appt: a, compact: true),
              ),

          // ---- quick actions
          const SectionHeader('Quick Actions'),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.calendar_month,
                  label: 'Book Appointment',
                  filled: true,
                  onTap: () => _push(context, const BookingScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.pets,
                  label: 'Add Pet',
                  onTap: () => _push(context, const AddPetScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.vaccines,
                  label: 'Add Vaccine',
                  onTap: () {
                    if (s.pets.isEmpty) {
                      showSnack(context, 'Add a pet first');
                      return;
                    }
                    _push(context, const AddVaccineScreen());
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.search,
                  label: 'Browse Services',
                  onTap: () => shellTab.value = 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.value, required this.label, required this.icon, required this.onTap});
  final int value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(height: 4),
                Text('$value',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.v, required this.onView});
  final Vaccination v;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final d = v.daysUntilDue!;
    final left = d < 0
        ? '${-d} day${d == -1 ? '' : 's'} overdue'
        : d == 0
            ? 'due today'
            : '$d day${d == 1 ? '' : 's'} left';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reminder: ${v.vaccineName}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                const SizedBox(height: 2),
                Text('${v.petName} is due on ${fmtDate(v.nextDueDate!)} ($left)',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 34),
            ),
            onPressed: onView,
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap, this.filled = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 6),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    return filled
        ? ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: child)
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: Colors.white),
            child: child);
  }
}

/// Side menu opened by the ☰ button.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    void open(Widget page) {
      final nav = Navigator.of(context);
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => page));
    }

    void tab(int i) {
      Navigator.pop(context);
      shellTab.value = i;
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primaryLight,
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', width: 54, height: 54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.profile?.fullName ?? s.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 17)),
                        Text(s.user?.email ?? '',
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.home_outlined), title: const Text('Home'), onTap: () => tab(0)),
            ListTile(leading: const Icon(Icons.pets_outlined), title: const Text('My Pets'), onTap: () => tab(1)),
            ListTile(
                leading: const Icon(Icons.vaccines_outlined),
                title: const Text('Vaccinations'),
                onTap: () => open(const VaccinationsScreen())),
            ListTile(
                leading: const Icon(Icons.medical_services_outlined),
                title: const Text('Services'),
                onTap: () => tab(2)),
            ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('My Appointments'),
                onTap: () => tab(3)),
            ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Notifications'),
                trailing: s.unreadCount > 0
                    ? Badge(label: Text('${s.unreadCount}'))
                    : null,
                onTap: () => open(const NotificationsScreen())),
            ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () => open(const ProfileScreen())),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Log out', style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                final st = context.read<AppState>();
                Navigator.pop(context);
                shellTab.value = 0;
                await st.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

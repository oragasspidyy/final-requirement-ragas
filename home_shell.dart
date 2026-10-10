import 'package:flutter/material.dart';

import 'appointments/appointments_screen.dart';
import 'dashboard_screen.dart';
import 'pets/pets_screen.dart';
import 'services/services_screen.dart';

/// Lets any screen switch the bottom-navigation tab
/// (0 Home, 1 Pets, 2 Services, 3 Bookings).
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);

void goToTab(BuildContext context, int index) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  shellTab.value = index;
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _pages = [
    DashboardScreen(),
    PetsScreen(),
    ServicesScreen(),
    AppointmentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, index, _) {
        return PopScope(
          canPop: index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) shellTab.value = 0;
          },
          child: Scaffold(
            body: IndexedStack(index: index, children: _pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => shellTab.value = i,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.pets_outlined),
                    selectedIcon: Icon(Icons.pets),
                    label: 'Pets'),
                NavigationDestination(
                    icon: Icon(Icons.medical_services_outlined),
                    selectedIcon: Icon(Icons.medical_services),
                    label: 'Services'),
                NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Bookings'),
              ],
            ),
          ),
        );
      },
    );
  }
}

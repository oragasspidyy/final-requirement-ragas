import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../widgets/common.dart';
import '../booking/booking_screen.dart';
import 'appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _searching = false;
  String _query = '';

  List<Appointment> _filter(List<Appointment> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((a) =>
            a.serviceName.toLowerCase().contains(q) ||
            a.petName.toLowerCase().contains(q) ||
            a.provider.toLowerCase().contains(q) ||
            a.bookingId.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final upcoming = _filter(s.upcomingAppointments);
    final past = _filter(s.pastAppointments);
    final cancelled = _filter(s.cancelledAppointments);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: _searching
              ? TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search pet, service, clinic…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                )
              : const Text('My Appointments'),
          actions: [
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search),
              onPressed: () => setState(() {
                _searching = !_searching;
                if (!_searching) _query = '';
              }),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming (${upcoming.length})'),
              const Tab(text: 'Past'),
              const Tab(text: 'Cancelled'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const BookingScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Book'),
        ),
        body: TabBarView(
          children: [
            _List(items: upcoming, emptyText: 'No upcoming appointments', legend: true),
            _List(items: past, emptyText: 'No past appointments'),
            _List(items: cancelled, emptyText: 'No cancelled appointments'),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items, required this.emptyText, this.legend = false});
  final List<Appointment> items;
  final String emptyText;
  final bool legend;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        if (items.isEmpty)
          EmptyState(
            icon: Icons.event_note_outlined,
            title: emptyText,
            message: 'Book a vet visit, grooming or other service for your pet.',
          ),
        for (final a in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppointmentCard(appt: a),
          ),
        if (legend) const _Legend(),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        color: Colors.white,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status legend', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip('pending'),
              StatusChip('confirmed'),
              StatusChip('completed'),
              StatusChip('cancelled'),
            ],
          ),
        ],
      ),
    );
  }
}

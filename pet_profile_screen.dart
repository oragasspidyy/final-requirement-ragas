import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../appointments/appointment_card.dart';
import '../booking/booking_screen.dart';
import '../vaccines/add_vaccine_screen.dart';
import '../vaccines/vaccinations_screen.dart';
import 'add_pet_screen.dart';
import 'pets_screen.dart';

class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pet = s.petById(petId);
    if (pet == null) {
      // Pet was deleted.
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
            icon: Icons.pets, title: 'Pet not found', message: 'This pet was removed.'),
      );
    }
    final vaccines = s.vaccinations.where((v) => v.petId == pet.id).toList();
    final appts = s.appointments.where((a) => a.petId == pet.id).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(pet.name),
          actions: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddPetScreen(pet: pet))),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'vaccine') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddVaccineScreen(petId: pet.id)));
                } else if (v == 'delete') {
                  final deleted = await confirmDeletePet(context, pet);
                  if (deleted && context.mounted) Navigator.pop(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'vaccine', child: Text('Add vaccination')),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete pet', style: TextStyle(color: AppColors.danger))),
              ],
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  children: [
                    PetAvatar(pet: pet, size: 150),
                    const SizedBox(height: 12),
                    Text(pet.name,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    Text(pet.speciesBreed,
                        style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _Stat('Age', pet.ageLabel),
                        const SizedBox(width: 10),
                        _Stat('Gender', pet.gender),
                        const SizedBox(width: 10),
                        _Stat('Weight', pet.weightLabel),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: TabBar(
                tabs: [
                  Tab(text: 'Vaccines'),
                  Tab(text: 'Appointments'),
                  Tab(text: 'Notes'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _VaccinesTab(pet: pet, vaccines: vaccines),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (appts.isEmpty)
                    const EmptyState(
                        icon: Icons.event_note_outlined,
                        title: 'No appointments',
                        message: 'Bookings for this pet will appear here.'),
                  for (final a in appts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppointmentCard(appt: a),
                    ),
                ],
              ),
              _NotesTab(pet: pet),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookingScreen(initialPetId: pet.id)),
              ),
              icon: const Icon(Icons.calendar_month),
              label: Text('Book Appointment for ${pet.name}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _VaccinesTab extends StatelessWidget {
  const _VaccinesTab({required this.pet, required this.vaccines});
  final Pet pet;
  final List<Vaccination> vaccines;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (vaccines.isEmpty)
          const EmptyState(
              icon: Icons.vaccines_outlined,
              title: 'No vaccinations yet',
              message: 'Keep track of shots and next due dates.'),
        for (final v in vaccines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VaccineCard(v: v, showPetName: false),
          ),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AddVaccineScreen(petId: pet.id))),
          icon: const Icon(Icons.add),
          label: const Text('Add vaccination'),
        ),
      ],
    );
  }
}

class _NotesTab extends StatefulWidget {
  const _NotesTab({required this.pet});
  final Pet pet;

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.pet.notes);
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AppState>().updatePetNotes(widget.pet.id, _ctrl.text.trim());
      if (mounted) {
        FocusScope.of(context).unfocus();
        showSnack(context, 'Notes saved');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to save notes', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _ctrl,
          minLines: 6,
          maxLines: 12,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText:
                'Allergies, diet, behaviour, medications, vet instructions…',
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save Notes'),
        ),
      ],
    );
  }
}

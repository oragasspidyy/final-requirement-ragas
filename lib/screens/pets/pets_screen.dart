import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../vaccines/vaccinations_screen.dart';
import 'add_pet_screen.dart';
import 'pet_profile_screen.dart';

Future<bool> confirmDeletePet(BuildContext context, Pet pet) async {
  final state = context.read<AppState>();
  final ok = await confirmDialog(
    context,
    title: 'Delete ${pet.name}?',
    message:
        'This removes ${pet.name}\'s profile and vaccination records, and cancels upcoming appointments. This cannot be undone.',
    confirmText: 'Delete',
    destructive: true,
  );
  if (!ok) return false;
  try {
    await state.deletePet(pet);
    if (context.mounted) showSnack(context, '${pet.name} deleted');
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, 'Failed to delete: $e', error: true);
    return false;
  }
}

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<bool> _swipeActions(Pet pet) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('Edit ${pet.name}'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('Delete ${pet.name}',
                  style: const TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return false;
    if (choice == 'edit') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => AddPetScreen(pet: pet)));
      return false;
    }
    if (choice == 'delete') {
      // Delete then let the live list update; don't let Dismissible remove it
      // itself (avoids "dismissed widget still in tree" errors).
      await confirmDeletePet(context, pet);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _query.toLowerCase();
    final pets = s.pets
        .where((p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.breed.toLowerCase().contains(q) ||
            p.species.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        actions: [
          IconButton(
            tooltip: 'Vaccinations',
            icon: const Icon(Icons.vaccines_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VaccinationsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddPetScreen())),
        child: const Icon(Icons.add, size: 30),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search pets by name or breed',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      }),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 14),
          if (s.pets.isEmpty)
            EmptyState(
              icon: Icons.pets,
              title: 'No pets yet',
              message: 'Add your first pet to start tracking their health.',
              action: FilledButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddPetScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Add Pet'),
              ),
            )
          else if (pets.isEmpty)
            const EmptyState(
                icon: Icons.search_off,
                title: 'No matches',
                message: 'Try a different name or breed.'),
          for (final p in pets)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey(p.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _swipeActions(p),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.edit_outlined, color: AppColors.primary),
                      SizedBox(width: 16),
                      Icon(Icons.delete_outline, color: AppColors.danger),
                    ],
                  ),
                ),
                child: _PetCard(pet: p),
              ),
            ),
          if (s.pets.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Swipe left on a card to Edit or Delete',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PetProfileScreen(petId: pet.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PetAvatar(pet: pet, size: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(pet.speciesBreed,
                        style: const TextStyle(color: AppColors.muted)),
                    Text('${pet.ageLabel} · ${pet.gender}',
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

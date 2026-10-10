import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'add_vaccine_screen.dart';

class VaccinationsScreen extends StatefulWidget {
  const VaccinationsScreen({super.key});

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  String? _petFilter; // null = all pets
  bool _searching = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    bool match(Vaccination v) {
      if (_petFilter != null && v.petId != _petFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return v.vaccineName.toLowerCase().contains(q) ||
          v.petName.toLowerCase().contains(q) ||
          v.clinic.toLowerCase().contains(q);
    }

    final due = s.dueSoonVaccinations.where(match).toList();
    final dueIds = due.map((e) => e.id).toSet();
    final history =
        s.vaccinations.where(match).where((v) => !dueIds.contains(v.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search vaccine, pet, clinic…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : const Text('Vaccinations'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (s.pets.isEmpty) {
            showSnack(context, 'Add a pet first');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddVaccineScreen(petId: _petFilter)),
          );
        },
        child: const Icon(Icons.add, size: 30),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All pets',
                  selected: _petFilter == null,
                  onTap: () => setState(() => _petFilter = null),
                ),
                for (final p in s.pets)
                  _FilterChip(
                    label: p.name,
                    selected: _petFilter == p.id,
                    onTap: () => setState(() => _petFilter = p.id),
                  ),
              ],
            ),
          ),
          if (due.isEmpty && history.isEmpty)
            const EmptyState(
              icon: Icons.vaccines_outlined,
              title: 'No vaccination records',
              message: 'Tap + to add your pet\'s vaccination history.',
            ),
          if (due.isNotEmpty) ...[
            const SectionHeader('Due soon'),
            for (final v in due)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VaccineCard(v: v, highlight: true),
              ),
          ],
          if (history.isNotEmpty) ...[
            const SectionHeader('History'),
            for (final v in history)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VaccineCard(v: v),
              ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Vaccination record card used on the Vaccinations list and pet profile.
class VaccineCard extends StatelessWidget {
  const VaccineCard({
    super.key,
    required this.v,
    this.highlight = false,
    this.showPetName = true,
  });
  final Vaccination v;
  final bool highlight;
  final bool showPetName;

  void _openDetails(BuildContext context) {
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${v.vaccineName} – ${v.petName}',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              InfoRow('Date given', fmtDate(v.dateGiven)),
              InfoRow('Next due',
                  v.nextDueDate == null ? 'Not set' : fmtDate(v.nextDueDate!)),
              InfoRow('Clinic / Vet', v.clinic.isEmpty ? '—' : v.clinic),
              InfoRow('Reminder', v.remind ? '3 days before' : 'Off', last: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger, width: 1.5),
                      ),
                      onPressed: () async {
                        final ok = await confirmDialog(ctx,
                            title: 'Delete record?',
                            message: 'This vaccination record will be removed.',
                            confirmText: 'Delete',
                            destructive: true);
                        if (!ok) return;
                        await state.deleteVaccination(v);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddVaccineScreen(existing: v)),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = v.status;
    final isLatest = context.select<AppState, bool>((s) => s.isLatestRecord(v));
    String? badge;
    if (isLatest) {
      switch (status) {
        case VaccineStatus.overdue:
          badge = 'Overdue';
          break;
        case VaccineStatus.dueSoon:
          final d = v.daysUntilDue!;
          badge = highlight ? (d == 0 ? 'Today' : '$d day${d == 1 ? '' : 's'}') : 'Due soon';
          break;
        case VaccineStatus.upToDate:
          badge = 'Up to date';
          break;
        case VaccineStatus.noDueDate:
          badge = null;
      }
    }
    final title = showPetName ? '${v.vaccineName} – ${v.petName}' : v.vaccineName;
    final subtitle = highlight && v.nextDueDate != null
        ? 'Next due: ${fmtDate(v.nextDueDate!)}'
        : 'Given ${fmtDate(v.dateGiven)}'
            '${v.nextDueDate == null ? '' : ' · Due ${fmtDate(v.nextDueDate!)}'}';

    return Card(
      color: highlight ? AppColors.warningBg : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: highlight ? AppColors.warning : AppColors.primaryLight,
                child: Icon(Icons.vaccines,
                    color: highlight ? Colors.white : AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                if (highlight && status == VaccineStatus.dueSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  )
                else
                  StatusChip(status == VaccineStatus.overdue
                      ? 'overdue'
                      : status == VaccineStatus.dueSoon
                          ? 'due soon'
                          : 'up to date'),
              ] else
                const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

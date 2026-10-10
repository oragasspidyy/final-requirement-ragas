import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/catalog.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Add a vaccination record, or edit [existing].
class AddVaccineScreen extends StatefulWidget {
  const AddVaccineScreen({super.key, this.petId, this.existing});
  final String? petId;
  final Vaccination? existing;

  @override
  State<AddVaccineScreen> createState() => _AddVaccineScreenState();
}

class _AddVaccineScreenState extends State<AddVaccineScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _petId;
  String? _vaccine;
  final _otherVaccine = TextEditingController();
  late final TextEditingController _clinic;
  DateTime? _given;
  DateTime? _nextDue;
  bool _remind = true;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _petId = e?.petId ?? widget.petId;
    _clinic = TextEditingController(text: e?.clinic ?? '');
    if (e != null) {
      if (vaccineOptions.contains(e.vaccineName)) {
        _vaccine = e.vaccineName;
      } else {
        _vaccine = 'Other';
        _otherVaccine.text = e.vaccineName;
      }
      _given = e.dateGiven;
      _nextDue = e.nextDueDate;
      _remind = e.remind;
    } else {
      final now = DateTime.now();
      _given = DateTime(now.year, now.month, now.day);
      _nextDue = DateTime(now.year + 1, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _otherVaccine.dispose();
    _clinic.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final pet = state.petById(_petId!);
    if (pet == null) return;
    final name = _vaccine == 'Other' ? _otherVaccine.text.trim() : _vaccine!;
    setState(() => _saving = true);
    try {
      await state.saveVaccination(
        id: widget.existing?.id,
        pet: pet,
        vaccineName: name,
        dateGiven: _given!,
        nextDueDate: _nextDue,
        clinic: _clinic.text,
        remind: _remind,
      );
      if (!mounted) return;
      showSnack(context, _editing ? 'Record updated' : 'Vaccination saved');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to save: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<AppState>().pets;
    final petIds = pets.map((p) => p.id).toList();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Text(_editing ? 'Edit Vaccination' : 'Add Vaccination'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel('Pet *'),
                AppDropdown<String>(
                  value: _petId,
                  items: petIds,
                  hint: 'Select pet',
                  labelOf: (id) => pets.firstWhere((p) => p.id == id).name,
                  onChanged: _editing ? null : (v) => setState(() => _petId = v),
                  validator: (v) => v == null ? 'Please select a pet' : null,
                ),
                const FieldLabel('Vaccine name *'),
                AppDropdown<String>(
                  value: _vaccine,
                  items: vaccineOptions,
                  hint: 'Select vaccine',
                  onChanged: (v) => setState(() => _vaccine = v),
                  validator: (v) => v == null ? 'Please select a vaccine' : null,
                ),
                if (_vaccine == 'Other') ...[
                  const FieldLabel('Specify vaccine *'),
                  TextFormField(
                    controller: _otherVaccine,
                    decoration: const InputDecoration(hintText: 'Vaccine name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter the vaccine name' : null,
                  ),
                ],
                const FieldLabel('Date given *'),
                DateField(
                  value: _given,
                  firstDate: DateTime(2000),
                  lastDate: now,
                  onChanged: (d) => setState(() {
                    _given = d;
                    if (d != null && !_editing) {
                      _nextDue = DateTime(d.year + 1, d.month, d.day);
                    }
                  }),
                  validator: (d) => d == null ? 'Date given is required' : null,
                ),
                const FieldLabel('Next due date'),
                DateField(
                  value: _nextDue,
                  firstDate: _given ?? DateTime(2000),
                  lastDate: DateTime(now.year + 10),
                  clearable: true,
                  onChanged: (d) => setState(() => _nextDue = d),
                  validator: (d) {
                    if (d != null && _given != null && d.isBefore(_given!)) {
                      return 'Must be after the date given';
                    }
                    return null;
                  },
                ),
                const FieldLabel('Clinic / Veterinarian'),
                TextFormField(
                  controller: _clinic,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'e.g. Davao Vet Clinic'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _remind && _nextDue != null,
                  onChanged: _nextDue == null ? null : (v) => setState(() => _remind = v),
                  title: const Text('Remind me 3 days before due date'),
                  subtitle: _nextDue == null
                      ? const Text('Set a next due date to enable reminders')
                      : null,
                  activeTrackColor: AppColors.primary,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Save Record'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

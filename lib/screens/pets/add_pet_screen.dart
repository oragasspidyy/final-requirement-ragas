import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/catalog.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Add a new pet, or edit an existing one when [pet] is given.
class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key, this.pet});
  final Pet? pet;

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _weight;
  late final TextEditingController _otherBreed;
  late String _species;
  String? _breed;
  DateTime? _birthdate;
  late String _gender;
  String? _photoBase64;
  Uint8List? _photoBytes;
  bool _saving = false;

  bool get _editing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _name = TextEditingController(text: p?.name ?? '');
    _weight = TextEditingController(
        text: p?.weight == null ? '' : p!.weight!.toString().replaceAll(RegExp(r'\.0$'), ''));
    _species = p?.species ?? 'Dog';
    if (!speciesOptions.contains(_species)) _species = 'Other';
    final breeds = breedOptions[_species]!;
    _otherBreed = TextEditingController();
    if (p != null && p.breed.isNotEmpty) {
      if (breeds.contains(p.breed)) {
        _breed = p.breed;
      } else {
        _breed = 'Other';
        _otherBreed.text = p.breed;
      }
    }
    _birthdate = p?.birthdate;
    _gender = p?.gender ?? 'Male';
    _photoBase64 = p?.photoBase64;
    _photoBytes = p?.photoBytes;
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _otherBreed.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_photoBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Remove photo',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _photoBytes = null;
                    _photoBase64 = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      // Small, compressed image so it fits inside a Firestore document
      // (no Firebase Storage / paid plan needed).
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 60,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 700 * 1024) {
        if (mounted) showSnack(context, 'That photo is too large. Try another one.', error: true);
        return;
      }
      setState(() {
        _photoBytes = bytes;
        _photoBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (mounted) showSnack(context, 'Could not open photo: $e', error: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final breed = _breed == 'Other' && _otherBreed.text.trim().isNotEmpty
        ? _otherBreed.text.trim()
        : (_breed ?? '');
    try {
      await context.read<AppState>().savePet(
            id: widget.pet?.id,
            name: _name.text,
            species: _species,
            breed: breed,
            birthdate: _birthdate,
            weight: double.tryParse(_weight.text.trim()),
            gender: _gender,
            photoBase64: _photoBase64,
          );
      if (!mounted) return;
      showSnack(context, _editing ? 'Pet updated' : '${_name.text.trim()} added!');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to save: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breeds = breedOptions[_species]!;
    final fallback = Pet(
      id: '',
      name: '',
      species: _species,
      breed: '',
      birthdate: null,
      weight: null,
      gender: _gender,
      photoBase64: null,
      notes: '',
      createdAt: DateTime.now(),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Text(_editing ? 'Edit Pet' : 'Add Pet'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: _photoBytes != null
                                      ? MemoryImage(_photoBytes!)
                                      : AssetImage(fallback.defaultAsset) as ImageProvider,
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 4,
                              bottom: 4,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.photo_camera, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_photoBytes == null ? 'Tap to add photo' : 'Tap to change photo',
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
                const FieldLabel('Pet name *'),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'e.g. Max'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Pet name is required' : null,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Species *'),
                          AppDropdown<String>(
                            value: _species,
                            items: speciesOptions,
                            onChanged: (v) => setState(() {
                              _species = v ?? 'Dog';
                              _breed = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Breed'),
                          AppDropdown<String>(
                            value: _breed,
                            items: breeds,
                            onChanged: (v) => setState(() => _breed = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_breed == 'Other') ...[
                  const FieldLabel('Specify breed'),
                  TextFormField(
                    controller: _otherBreed,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'e.g. Corgi'),
                  ),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Birthdate'),
                          DateField(
                            value: _birthdate,
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
                            hint: 'MM/DD/YYYY',
                            clearable: true,
                            onChanged: (d) => setState(() => _birthdate = d),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Weight (kg)'),
                          TextFormField(
                            controller: _weight,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                            decoration: const InputDecoration(hintText: 'e.g. 12'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final w = double.tryParse(v.trim());
                              if (w == null || w <= 0 || w > 150) return 'Invalid weight';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const FieldLabel('Gender *'),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final g in const ['Male', 'Female'])
                      ChoiceChip(
                        label: Text(g == 'Male' ? '♂ Male' : '♀ Female'),
                        selected: _gender == g,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _gender == g ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _gender = g),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(_editing ? 'Save Changes' : 'Save Pet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

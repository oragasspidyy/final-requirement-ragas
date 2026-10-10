import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _name = TextEditingController(
        text: s.profile?.fullName ?? s.user?.displayName ?? '');
    _mobile = TextEditingController(text: s.profile?.mobile ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().updateProfile(_name.text, _mobile.text);
      if (mounted) showSnack(context, 'Profile updated');
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to update profile', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final state = context.read<AppState>();
    final ok = await confirmDialog(context,
        title: 'Log out?', message: 'You can log back in anytime.', confirmText: 'Log out');
    if (!ok || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    shellTab.value = 0;
    await state.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (s.profile?.fullName.isNotEmpty ?? false)
                        ? s.profile!.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(s.user?.email ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Count('Pets', s.pets.length),
                  _Count('Vaccines', s.vaccinations.length),
                  _Count('Bookings', s.appointments.length),
                ],
              ),
              const FieldLabel('Full name'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
              ),
              const FieldLabel('Mobile number'),
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^09\d{9}$').hasMatch(v)) {
                    return 'Enter an 11-digit number starting with 09';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save Changes'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final email = s.user?.email;
                  if (email == null) return;
                  try {
                    await s.sendPasswordReset(email);
                    if (context.mounted) showSnack(context, 'Password reset link sent to $email');
                  } catch (_) {
                    if (context.mounted) {
                      showSnack(context, 'Could not send reset email', error: true);
                    }
                  }
                },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Change password'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text('$value',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      );
}

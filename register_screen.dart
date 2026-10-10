import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agree = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _mobile, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      showSnack(context, 'Please agree to the Terms and Privacy Policy',
          error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppState>().register(
            fullName: _name.text,
            email: _email.text,
            mobile: _mobile.text,
            password: _password.text,
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showSnack(context, authErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms and Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'PetCareHub stores your account details, pet profiles, vaccination '
            'records and appointments in a secure cloud database so you can access '
            'them on your device.\n\n'
            '• Only you can view and edit your pets\' records.\n'
            '• Your mobile number is used only to contact you about bookings.\n'
            '• Payments for services are made directly at the clinic.\n'
            '• You may delete your pets and records at any time.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel('Full name'),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Juan Dela Cruz'),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
                ),
                const FieldLabel('Email address'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'juan@email.com'),
                  validator: validateEmail,
                ),
                const FieldLabel('Mobile number'),
                TextFormField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(hintText: '09XX XXX XXXX'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mobile number is required';
                    if (!RegExp(r'^09\d{9}$').hasMatch(v)) {
                      return 'Enter an 11-digit number starting with 09';
                    }
                    return null;
                  },
                ),
                const FieldLabel('Password'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const FieldLabel('Confirm password'),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(hintText: 'Re-enter password'),
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('I agree to the '),
                          GestureDetector(
                            onTap: _showTerms,
                            child: const Text('Terms and Privacy Policy',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

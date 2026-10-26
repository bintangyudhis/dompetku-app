import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_shell.dart';
import '../widgets/primary_button.dart';

/// Layar daftar: aturan validasi disamakan dengan server web
/// (nama 2–80 karakter, email valid, kata sandi 6–72 karakter) agar
/// pesan galat lokal tidak bertentangan dengan pesan server.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthState>();
    final ok = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      // Sesi sudah aktif; kembali ke layar pertama yang kini Beranda.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Buat akun DompetKu',
      subtitle: 'Satu akun berlaku di web dan di aplikasi ini.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Sudah punya akun?'),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Masuk'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nama',
              controller: _nameController,
              autofillHints: const [AutofillHints.name],
              validator: (value) {
                final name = (value ?? '').trim();
                if (name.length < 2) return 'Nama minimal 2 karakter.';
                if (name.length > 80) return 'Nama maksimal 80 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return 'Email wajib diisi.';
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Alamat email tidak valid.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Kata sandi',
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.length < 6) {
                  return 'Kata sandi minimal 6 karakter.';
                }
                if (password.length > 72) {
                  return 'Kata sandi maksimal 72 karakter.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Ulangi kata sandi',
              controller: _confirmController,
              obscureText: _obscurePassword,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Kata sandi tidak sama.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Daftar',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

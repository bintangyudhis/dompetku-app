import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_shell.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';

/// Layar masuk: email + kata sandi yang sama dengan akun web DompetKu.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthState>();
    final ok = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok && auth.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error!)));
    }
    // Bila sukses, AuthGate otomatis mengganti layar ini dengan Beranda.
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Selamat datang kembali',
      subtitle: 'Masuk dengan akun DompetKu yang sama seperti di web.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Belum punya akun?'),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            child: const Text('Daftar'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              autofillHints: const [AutofillHints.password],
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
                if ((value ?? '').isEmpty) return 'Kata sandi wajib diisi.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Masuk',
              isLoading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sesi login tersimpan aman di perangkat ini, jadi tidak perlu '
              'masuk berulang kali.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

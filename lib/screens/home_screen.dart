import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';

/// Beranda sementara: tujuan auth guard setelah login berhasil.
/// Ringkasan, grafik, dan daftar transaksi dibangun di hari berikutnya;
/// layar ini memastikan alur login → beranda → keluar sudah utuh.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthState>().session;
    return Scaffold(
      appBar: AppBar(title: const Text('DompetKu')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Halo, ${session?.user.name ?? ''}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(session?.user.email ?? ''),
            const SizedBox(height: 24),
            const Text(
              'Ringkasan keuanganmu akan tampil di sini: saldo, pemasukan, '
              'pengeluaran, dan transaksi terbaru dari akun yang sama '
              'dengan DompetKu web.',
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => context.read<AuthState>().logout(),
              child: const Text('Keluar'),
            ),
          ],
        ),
      ),
    );
  }
}

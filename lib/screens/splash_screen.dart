import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Layar pembuka: ditampilkan hanya selama sesi tersimpan dipulihkan.
/// Tidak ada logo gambar — nama produk + indikator saja, supaya ringan.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DompetKu',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Uangmu, tercatat rapi.',
              style: TextStyle(fontSize: 16, color: AppTheme.muted),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }
}

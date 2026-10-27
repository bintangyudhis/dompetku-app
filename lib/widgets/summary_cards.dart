import 'package:flutter/material.dart';

import '../data/models/summary.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Kartu ringkasan dasbor: saldo besar di atas, lalu dua angka bulan ini
/// berdampingan. Warna hanya satu aksen hijau; angka negatif merah redup
/// supaya tetap terbaca tanpa warna-warni.
class SummaryCards extends StatelessWidget {
  const SummaryCards({required this.summary, super.key});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${formatRupiah(summary.saldo)}',
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MonthFigure(
                label: 'Masuk bulan ini',
                amount: summary.pemasukanBulanIni,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MonthFigure(
                label: 'Keluar bulan ini',
                amount: summary.pengeluaranBulanIni,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthFigure extends StatelessWidget {
  const _MonthFigure({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8D2C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${formatRupiah(amount)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

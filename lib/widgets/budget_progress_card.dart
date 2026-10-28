import 'package:flutter/material.dart';

import '../data/models/budget.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Satu baris budget: nama kategori, terpakai dari batas, dan bilah
/// progres. Warna bilah hanya menandai ambang server: hijau di bawah
/// 80%, kuning di 80–99%, merah bila sudah lewat — bukan dekorasi.
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Budget budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _barColor(BuildContext context) {
    if (budget.isOver) return Theme.of(context).colorScheme.error;
    if (budget.isWarning) return const Color(0xFFB7791F);
    return AppTheme.primaryGreen;
  }

  String get _statusLabel {
    if (budget.isOver) return 'Lewat batas';
    if (budget.isWarning) return 'Mendekati batas';
    return 'Aman';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  budget.categoryIcon ?? '💰',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    budget.categoryName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Ubah'),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Hapus'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: budget.progressRatio,
              color: _barColor(context),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rp${formatRupiah(budget.spent)} dari '
                  'Rp${formatRupiah(budget.amount)}',
                ),
                Text('${budget.percent}% · $_statusLabel'),
              ],
            ),
            if (budget.remaining >= 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Sisa Rp${formatRupiah(budget.remaining)}',
                  style: TextStyle(color: AppTheme.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

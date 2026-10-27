import 'package:flutter/material.dart';

import '../data/models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Satu baris transaksi: ikon kategori (teks), nama kategori + catatan,
/// tanggal, dan nominal bertanda (+ pemasukan / − pengeluaran).
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.item,
    this.onTap,
    super.key,
  });

  final TransactionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sign = item.isIncome ? '+' : '−';
    final amountStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: item.isIncome ? AppTheme.primaryGreen : const Color(0xFF9C3B2E),
    );
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: AppTheme.paper,
        foregroundColor: AppTheme.ink,
        child: Text(item.categoryIcon ?? '•'),
      ),
      title: Text(item.categoryName),
      subtitle: item.note != null && item.note!.isNotEmpty
          ? Text(
              item.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$sign Rp ${formatRupiah(item.amount)}', style: amountStyle),
          Text(
            formatTanggal(item.date),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

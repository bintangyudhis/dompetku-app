import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sync_service.dart';

/// Indikator status sinkronisasi di bilah aplikasi.
///
/// Empat keadaan, tanpa warna-warni: sedang sinkron, ada perubahan
/// menunggu, sinkron terakhir gagal, atau tersinkron pada jam tertentu.
/// Mengetuk chip menjalankan sinkronisasi (atau mengulang yang gagal).
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({required this.onSyncPressed, super.key});

  final VoidCallback onSyncPressed;

  String _time(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, sync, _) {
        final String label;
        final IconData icon;
        if (sync.syncing) {
          label = 'Menyinkronkan…';
          icon = Icons.sync_outlined;
        } else if (sync.lastError != null) {
          label = 'Sinkron gagal, ketuk untuk coba lagi';
          icon = Icons.sync_problem_outlined;
        } else if (sync.pendingCount > 0) {
          label = '${sync.pendingCount} perubahan menunggu sinkron';
          icon = Icons.schedule_outlined;
        } else if (sync.lastSyncedAt != null) {
          label = 'Tersinkron ${_time(sync.lastSyncedAt!)}';
          icon = Icons.cloud_done_outlined;
        } else {
          label = 'Belum pernah sinkron';
          icon = Icons.cloud_off_outlined;
        }
        return ActionChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          onPressed: sync.syncing ? null : onSyncPressed,
        );
      },
    );
  }
}

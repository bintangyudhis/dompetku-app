import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../state/dashboard_state.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/weekly_chart.dart';

/// Layar dasbor: ringkasan, grafik 7 hari, transaksi terbaru.
///
/// Tarik ke bawah untuk memuat ulang (pull-to-refresh); galat jaringan
/// tampil sebagai spanduk dengan tombol coba lagi, bukan layar kosong.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({this.onSeeAll, super.key});

  final VoidCallback? onSeeAll;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthState>().session?.token;
      if (token != null) context.read<DashboardState>().load(token);
    });
  }

  Future<void> _refresh() async {
    final token = context.read<AuthState>().session?.token;
    if (token != null) await context.read<DashboardState>().load(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DompetKu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => context.read<AuthState>().logout(),
          ),
        ],
      ),
      body: Consumer<DashboardState>(
        builder: (context, state, _) {
          if (state.loading && state.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = state.summary;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (state.error != null) ...[
                  _ErrorBanner(message: state.error!, onRetry: _refresh),
                  const SizedBox(height: 16),
                ],
                if (state.fromCache) ...[
                  const ListTile(
                    leading: Icon(Icons.cloud_off_outlined),
                    title: Text('Menampilkan data offline terakhir.'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                ],
                if (summary != null) SummaryCards(summary: summary),
                const SizedBox(height: 16),
                WeeklyChart(days: state.lastSevenDaysExpense),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi terbaru',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: widget.onSeeAll,
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
                if (state.recentFive.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Belum ada transaksi. Tambahkan yang pertama dari '
                      'layar Transaksi.',
                    ),
                  )
                else
                  for (final item in state.recentFive)
                    TransactionTile(item: item),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEFEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

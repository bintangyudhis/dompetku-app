import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sync_service.dart';
import '../state/auth_state.dart';
import '../state/budgets_state.dart';
import '../state/categories_state.dart';
import '../state/dashboard_state.dart';
import '../state/transactions_state.dart';
import '../widgets/sync_status_chip.dart';
import 'budgets_screen.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';

/// Shell utama setelah login: navigasi bawah Dasbor / Transaksi /
/// Kategori / Anggaran.
///
/// Semua state dibuat di sini supaya layar berbagi satu sumber data
/// selama aplikasi berjalan. Baris chip sinkronisasi di atas layar
/// menampilkan status antrean offline; mengetuknya menjalankan
/// sinkronisasi lalu memuat ulang semua layar bila berhasil.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _index = 0;
  var _syncInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncInit) return;
    _syncInit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncService>().refresh();
    });
  }

  Future<void> _syncAll() async {
    // Ditangkap dulu: konteks tidak boleh dipakai setelah await.
    final token = context.read<AuthState>().session?.token;
    if (token == null) return;
    final sync = context.read<SyncService>();
    final dashboard = context.read<DashboardState>();
    final transactions = context.read<TransactionsState>();
    final categories = context.read<CategoriesState>();
    final budgets = context.read<BudgetsState>();
    final ok = await sync.sync(token);
    if (!mounted || !ok) return;
    await dashboard.load(token);
    await transactions.load(token);
    await categories.load(token);
    await budgets.load(token);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardState()),
        ChangeNotifierProvider(create: (_) => TransactionsState()),
        ChangeNotifierProvider(create: (_) => CategoriesState()),
        ChangeNotifierProvider(create: (_) => BudgetsState()),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SyncStatusChip(onSyncPressed: _syncAll),
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: [
                    DashboardScreen(onSeeAll: () => setState(() => _index = 1)),
                    const TransactionsScreen(),
                    const CategoriesScreen(),
                    const BudgetsScreen(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              setState(() => _index = value);
              // Antrean bisa bertambah saat layar lain gagal jaringan:
              // segarkan angka chip tiap pindah tab.
              context.read<SyncService>().refresh();
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Dasbor',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Transaksi',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'Kategori',
              ),
              NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings),
                label: 'Anggaran',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

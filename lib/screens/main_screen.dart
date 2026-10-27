import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../state/transactions_state.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';

/// Shell utama setelah login: navigasi bawah Dasbor / Transaksi.
///
/// Kedua state dibuat di sini supaya dasbor dan transaksi berbagi satu
/// sumber data selama aplikasi berjalan.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardState()),
        ChangeNotifierProvider(create: (_) => TransactionsState()),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              DashboardScreen(onSeeAll: () => setState(() => _index = 1)),
              const TransactionsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
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
            ],
          ),
        ),
      ),
    );
  }
}

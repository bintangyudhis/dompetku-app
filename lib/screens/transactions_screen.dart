import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories_api.dart';
import '../data/models/app_category.dart';
import '../data/models/transaction.dart';
import '../state/auth_state.dart';
import '../state/transactions_state.dart';
import '../widgets/transaction_form_sheet.dart';
import '../widgets/transaction_tile.dart';

/// Layar transaksi: pencarian, filter tipe, tambah/ubah/hapus.
///
/// Ketuk baris untuk memilih Ubah atau Hapus; hapus selalu minta
/// konfirmasi dulu. Kategori formulir dimuat sekali saat layar dibuka.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  var _loaded = false;
  List<AppCategory> _categories = [];

  String? get _token => context.read<AuthState>().session?.token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = _token;
      if (token == null) return;
      context.read<TransactionsState>().load(token);
      final categories = await CategoriesApi().list(token: token);
      if (mounted) setState(() => _categories = categories);
    });
  }

  Future<void> _refresh() async {
    final token = _token;
    if (token != null) {
      await context.read<TransactionsState>().load(token);
    }
  }

  Future<void> _openForm({TransactionItem? initial}) async {
    final token = _token;
    if (token == null) return;
    // Ditangkap di sini: konteks builder bottom sheet tidak mewarisi
    // provider MainScreen (sheet hidup di rute Navigator tersendiri).
    final state = context.read<TransactionsState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionFormSheet(
        categories: _categories,
        initial: initial,
        onSubmit: (draft) {
          if (initial == null) return state.add(token, draft);
          return state.edit(token, draft);
        },
      ),
    );
  }

  Future<void> _confirmDelete(TransactionItem item) async {
    final token = _token;
    if (token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: Text(
          'Transaksi ${item.categoryName} ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<TransactionsState>().remove(token, item.id);
    }
  }

  Future<void> _showActions(TransactionItem item) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Ubah'),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Hapus'),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'edit') {
      await _openForm(initial: item);
    } else if (choice == 'delete') {
      await _confirmDelete(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Tambah transaksi',
        child: const Icon(Icons.add),
      ),
      body: Consumer<TransactionsState>(
        builder: (context, state, _) {
          if (state.loading && state.visible.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Cari catatan atau kategori',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: state.setQuery,
                ),
                const SizedBox(height: 12),
                SegmentedButton<TransactionFilter>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionFilter.all,
                      label: Text('Semua'),
                    ),
                    ButtonSegment(
                      value: TransactionFilter.income,
                      label: Text('Masuk'),
                    ),
                    ButtonSegment(
                      value: TransactionFilter.expense,
                      label: Text('Keluar'),
                    ),
                  ],
                  selected: {state.filter},
                  onSelectionChanged: (values) =>
                      state.setFilter(values.first),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Color(0xFF9C3B2E)),
                  ),
                ],
                const SizedBox(height: 8),
                if (state.visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Tidak ada transaksi yang cocok. Coba ubah pencarian '
                      'atau filter.',
                    ),
                  )
                else
                  for (final item in state.visible)
                    TransactionTile(
                      item: item,
                      onTap: () => _showActions(item),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

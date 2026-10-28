import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories_api.dart';
import '../data/models/app_category.dart';
import '../data/models/budget.dart';
import '../state/auth_state.dart';
import '../state/budgets_state.dart';
import '../utils/format.dart';
import '../widgets/budget_form_sheet.dart';
import '../widgets/budget_progress_card.dart';

/// Layar budget bulan berjalan: total, daftar per kategori dengan
/// progres, tambah/ubah/hapus.
///
/// Kategori formulir dimuat sekali saat layar dibuka (seperti layar
/// transaksi), karena budget hanya berlaku untuk kategori pengeluaran.
/// Bila daftar berasal dari cache, spanduk "data offline" tampil di atas.
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  var _loaded = false;
  List<AppCategory> _expenseCategories = [];

  String? get _token =>
      context.read<AuthState>().session?.token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = _token;
      if (token == null) return;
      context.read<BudgetsState>().load(token);
      final categories = await CategoriesApi().list(
        token: token,
        type: 'EXPENSE',
      );
      if (mounted) setState(() => _expenseCategories = categories);
    });
  }

  Future<void> _refresh() async {
    final token = _token;
    if (token != null) await context.read<BudgetsState>().load(token);
  }

  Future<void> _openForm({Budget? initial}) async {
    final token = _token;
    if (token == null) return;
    // Ditangkap di sini: konteks builder bottom sheet tidak mewarisi
    // provider MainScreen (sheet hidup di rute Navigator tersendiri).
    final state = context.read<BudgetsState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BudgetFormSheet(
        expenseCategories: _expenseCategories,
        initial: initial,
        onSubmit: (draft) {
          if (initial == null) return state.add(token, draft);
          return state.edit(token, draft);
        },
      ),
    );
  }

  Future<void> _confirmDelete(Budget budget) async {
    final token = _token;
    if (token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus budget?'),
        content: Text(
          'Budget ${budget.categoryName} bulan ini akan dihapus. '
          'Transaksinya tidak ikut terhapus.',
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
      await context.read<BudgetsState>().remove(token, budget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anggaran')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Tambah budget',
        child: const Icon(Icons.add),
      ),
      body: Consumer<BudgetsState>(
        builder: (context, state, _) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final children = <Widget>[];
          if (state.fromCache) {
            children.add(
              const ListTile(
                leading: Icon(Icons.cloud_off_outlined),
                title: Text('Menampilkan data offline terakhir.'),
              ),
            );
          }
          if (state.error != null) {
            children.add(
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(state.error!),
              ),
            );
          }
          if (state.notice != null) {
            children.add(
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(state.notice!),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: state.clearNotice,
                ),
              ),
            );
          }
          if (state.items.isNotEmpty) {
            children.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Terpakai Rp${formatRupiah(state.totalSpent)} dari '
                  'batas Rp${formatRupiah(state.totalLimit)} bulan ini.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
            children.addAll(
              state.items.map(
                (budget) => BudgetProgressCard(
                  budget: budget,
                  onEdit: () => _openForm(initial: budget),
                  onDelete: () => _confirmDelete(budget),
                ),
              ),
            );
          } else if (children.isEmpty) {
            children.add(
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: Text(
                    'Belum ada budget bulan ini. Ketuk + untuk menambah.',
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(children: children),
          );
        },
      ),
    );
  }
}

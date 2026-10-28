import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/app_category.dart';
import '../state/auth_state.dart';
import '../state/categories_state.dart';
import '../widgets/category_form_sheet.dart';

/// Layar kategori: daftar per tipe, tambah/ubah/hapus.
///
/// Ketuk baris untuk memilih Ubah atau Hapus; hapus selalu minta
/// konfirmasi dulu, dan bila server menolak (kategori masih dipakai
/// transaksi) pesannya tampil di layar, bukan hilang diam-diam.
/// Bila daftar berasal dari cache, spanduk "data offline" tampil di atas.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  var _loaded = false;
  late final TabController _tabs;

  String? get _token =>
      context.read<AuthState>().session?.token;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = _token;
      if (token != null) context.read<CategoriesState>().load(token);
    });
  }

  Future<void> _refresh() async {
    final token = _token;
    if (token != null) await context.read<CategoriesState>().load(token);
  }

  Future<void> _openForm({AppCategory? initial}) async {
    final token = _token;
    if (token == null) return;
    // Ditangkap di sini: konteks builder bottom sheet tidak mewarisi
    // provider MainScreen (sheet hidup di rute Navigator tersendiri).
    final state = context.read<CategoriesState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryFormSheet(
        initial: initial,
        onSubmit: (draft) {
          if (initial == null) return state.add(token, draft);
          return state.edit(token, draft);
        },
      ),
    );
  }

  Future<void> _confirmDelete(AppCategory category) async {
    final token = _token;
    if (token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text(
          'Kategori ${category.name} akan dihapus. '
          'Bila masih dipakai transaksi, server akan menolaknya.',
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
      await context.read<CategoriesState>().remove(token, category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Tambah kategori',
        child: const Icon(Icons.add),
      ),
      body: Consumer<CategoriesState>(
        builder: (context, state, _) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: TabBarView(
              controller: _tabs,
              children: [
                _CategoryList(
                  categories: state.expense,
                  fromCache: state.fromCache,
                  error: state.error,
                  notice: state.notice,
                  onEdit: (c) => _openForm(initial: c),
                  onDelete: _confirmDelete,
                  onClearNotice: state.clearNotice,
                ),
                _CategoryList(
                  categories: state.income,
                  fromCache: state.fromCache,
                  error: state.error,
                  notice: state.notice,
                  onEdit: (c) => _openForm(initial: c),
                  onDelete: _confirmDelete,
                  onClearNotice: state.clearNotice,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.fromCache,
    required this.error,
    required this.notice,
    required this.onEdit,
    required this.onDelete,
    required this.onClearNotice,
  });

  final List<AppCategory> categories;
  final bool fromCache;
  final String? error;
  final String? notice;
  final void Function(AppCategory) onEdit;
  final void Function(AppCategory) onDelete;
  final VoidCallback onClearNotice;

  @override
  Widget build(BuildContext context) {
    final banners = <Widget>[];
    if (fromCache) {
      banners.add(
        const ListTile(
          leading: Icon(Icons.cloud_off_outlined),
          title: Text('Menampilkan data offline terakhir.'),
        ),
      );
    }
    if (error != null) {
      banners.add(
        ListTile(
          leading: const Icon(Icons.error_outline),
          title: Text(error!),
        ),
      );
    }
    if (notice != null) {
      banners.add(
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: Text(notice!),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClearNotice,
          ),
        ),
      );
    }
    if (categories.isEmpty && banners.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text('Belum ada kategori di sini. Ketuk + untuk menambah.'),
          ),
        ],
      );
    }
    return ListView(
      children: [
        ...banners,
        ...categories.map(
          (category) => ListTile(
            leading: Text(
              category.icon ?? '💰',
              style: const TextStyle(fontSize: 22),
            ),
            title: Text(category.name),
            subtitle: Text(category.isIncome ? 'Pemasukan' : 'Pengeluaran'),
            onTap: () async {
              final action = await showModalBottomSheet<String>(
                context: context,
                builder: (sheetContext) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Ubah'),
                        onTap: () =>
                            Navigator.of(sheetContext).pop('edit'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Hapus'),
                        onTap: () =>
                            Navigator.of(sheetContext).pop('delete'),
                      ),
                    ],
                  ),
                ),
              );
              if (action == 'edit') onEdit(category);
              if (action == 'delete') onDelete(category);
            },
          ),
        ),
      ],
    );
  }
}

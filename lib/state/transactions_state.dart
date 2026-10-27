import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/models/transaction.dart';
import '../data/transactions_api.dart';

/// Filter tipe di layar transaksi: semua, pemasukan saja, pengeluaran saja.
enum TransactionFilter { all, income, expense }

/// State layar transaksi: daftar + pencarian + filter + mutasi.
///
/// Setelah tambah/ubah/hapus, daftar dimuat ulang dari server supaya
/// yang tampil selalu sama dengan yang tersimpan di dompetku-web.
class TransactionsState extends ChangeNotifier {
  TransactionsState({TransactionsApi? api}) : _api = api ?? TransactionsApi();

  final TransactionsApi _api;

  bool _loading = false;
  String? _error;
  List<TransactionItem> _items = [];
  String _query = '';
  TransactionFilter _filter = TransactionFilter.all;

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  TransactionFilter get filter => _filter;

  /// Daftar setelah pencarian (catatan/kategori) dan filter tipe.
  List<TransactionItem> get visible {
    final q = _query.trim().toLowerCase();
    return _items.where((t) {
      if (_filter == TransactionFilter.income && !t.isIncome) return false;
      if (_filter == TransactionFilter.expense && t.isIncome) return false;
      if (q.isEmpty) return true;
      final haystack =
          '${t.note ?? ''} ${t.categoryName}'.toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(TransactionFilter value) {
    _filter = value;
    notifyListeners();
  }

  Future<void> load(String token) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _api.list(token: token, limit: 200);
    } catch (e) {
      _error = e is ApiException
          ? e.message
          : 'Gagal memuat transaksi. Coba lagi.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add(String token, TransactionItem draft) =>
      _mutate(token, () => _api.create(token: token, draft: draft));

  Future<bool> edit(String token, TransactionItem item) =>
      _mutate(token, () => _api.update(token: token, item: item));

  Future<bool> remove(String token, String id) =>
      _mutate(token, () async {
        await _api.delete(token: token, id: id);
        return null;
      });

  Future<bool> _mutate(
    String token,
    Future<TransactionItem?> Function() call,
  ) async {
    _error = null;
    notifyListeners();
    try {
      await call();
      await load(token);
      return true;
    } catch (e) {
      _error = e is ApiException
          ? e.message
          : 'Gagal menyimpan perubahan. Coba lagi.';
      notifyListeners();
      return false;
    }
  }
}

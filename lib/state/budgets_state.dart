import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/budgets_api.dart';
import '../data/models/budget.dart';
import '../data/offline_cache.dart';

/// State layar budget: daftar bulan berjalan + tambah/ubah/hapus.
///
/// Polanya sama dengan [CategoriesState]: gagal jaringan saat memuat
/// memakai cache ([fromCache]), gagal jaringan saat mutasi masuk antrean
/// sinkronisasi ([notice]). Galat server (mis. nominal di bawah minimum)
/// ditampilkan, bukan diantrekan.
class BudgetsState extends ChangeNotifier {
  BudgetsState({BudgetsApi? api, OfflineCache? cache})
    : _api = api ?? BudgetsApi(),
      _cache = cache ?? OfflineCache();

  final BudgetsApi _api;
  final OfflineCache _cache;

  bool _loading = false;
  String? _error;
  String? _notice;
  bool _fromCache = false;
  List<Budget> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  String? get notice => _notice;
  bool get fromCache => _fromCache;
  List<Budget> get items => List.unmodifiable(_items);

  /// Total batas semua kategori bulan ini, untuk ringkasan layar.
  int get totalLimit => _items.fold(0, (sum, b) => sum + b.amount);

  /// Total terpakai semua kategori bulan ini.
  int get totalSpent => _items.fold(0, (sum, b) => sum + b.spent);

  void clearNotice() {
    _notice = null;
    notifyListeners();
  }

  Future<void> load(String token) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _fromCache = false;
    notifyListeners();
    try {
      _items = await _api.list(token: token);
      await _cache.saveBudgets(_items.map((b) => b.toJson()).toList());
    } on ApiException catch (e) {
      final cached = await _cache.loadBudgets();
      if (cached.isNotEmpty) {
        _items = cached.map(Budget.fromJson).toList();
        _fromCache = true;
      } else {
        _error = e.message;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add(String token, Budget draft) async {
    try {
      await _api.create(token: token, draft: draft);
    } on ApiException catch (e) {
      if (e.statusCode != null) {
        _error = e.message;
        notifyListeners();
        return false;
      }
      await _cache.enqueuePending('budget_create', draft.toRequestJson());
      _notice = 'Budget tersimpan offline, akan dikirim saat sinkronisasi.';
      notifyListeners();
      return false;
    }
    await load(token);
    return true;
  }

  Future<bool> edit(String token, Budget budget) async {
    try {
      await _api.update(token: token, budget: budget);
    } on ApiException catch (e) {
      if (e.statusCode != null) {
        _error = e.message;
        notifyListeners();
        return false;
      }
      await _cache.enqueuePending('budget_update', {
        'id': budget.id,
        'amount': budget.amount,
      });
      _notice = 'Perubahan tersimpan offline, akan dikirim saat sinkronisasi.';
      notifyListeners();
      return false;
    }
    await load(token);
    return true;
  }

  Future<bool> remove(String token, String id) async {
    try {
      await _api.delete(token: token, id: id);
    } on ApiException catch (e) {
      if (e.statusCode != null) {
        _error = e.message;
        notifyListeners();
        return false;
      }
      await _cache.enqueuePending('budget_delete', {'id': id});
      _notice = 'Hapus tersimpan offline, akan dikirim saat sinkronisasi.';
      notifyListeners();
      return false;
    }
    await load(token);
    return true;
  }
}

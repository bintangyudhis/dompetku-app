import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/categories_api.dart';
import '../data/models/app_category.dart';
import '../data/offline_cache.dart';

/// State layar kategori: daftar + CRUD + fallback cache offline.
///
/// Bila jaringan gagal saat memuat, daftar dibaca dari cache dan
/// [fromCache] menyala supaya UI bisa menandainya. Bila jaringan gagal
/// saat tambah/ubah/hapus, perubahan masuk antrean sinkronisasi (bukan
/// hilang) dan [notice] menjelaskan bahwa perubahan menunggu koneksi.
class CategoriesState extends ChangeNotifier {
  CategoriesState({CategoriesApi? api, OfflineCache? cache})
    : _api = api ?? CategoriesApi(),
      _cache = cache ?? OfflineCache();

  final CategoriesApi _api;
  final OfflineCache _cache;

  bool _loading = false;
  String? _error;
  String? _notice;
  bool _fromCache = false;
  List<AppCategory> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  String? get notice => _notice;
  bool get fromCache => _fromCache;
  List<AppCategory> get items => List.unmodifiable(_items);

  List<AppCategory> get expense =>
      _items.where((c) => !c.isIncome).toList();

  List<AppCategory> get income => _items.where((c) => c.isIncome).toList();

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
      await _cache.saveCategories(_items.map((c) => c.toJson()).toList());
    } on ApiException catch (e) {
      final cached = await _cache.loadCategories();
      if (cached.isNotEmpty) {
        _items = cached.map(AppCategory.fromJson).toList();
        _fromCache = true;
      } else {
        _error = e.message;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add(String token, AppCategory draft) async {
    try {
      await _api.create(token: token, draft: draft);
    } on ApiException {
      await _cache.enqueuePending('category_create', draft.toRequestJson());
      _notice = 'Kategori tersimpan offline, akan dikirim saat sinkronisasi.';
      notifyListeners();
      return false;
    }
    await load(token);
    return true;
  }

  Future<bool> edit(String token, AppCategory category) async {
    try {
      await _api.update(token: token, category: category);
    } on ApiException {
      await _cache.enqueuePending('category_update', {
        ...category.toRequestJson(),
        'id': category.id,
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
      // Galat server (mis. kategori masih dipakai transaksi) bukan
      // galat jaringan: jangan antrekan, tampilkan pesannya.
      if (e.statusCode != null) {
        _error = e.message;
        notifyListeners();
        return false;
      }
      await _cache.enqueuePending('category_delete', {'id': id});
      _notice = 'Hapus tersimpan offline, akan dikirim saat sinkronisasi.';
      notifyListeners();
      return false;
    }
    await load(token);
    return true;
  }
}

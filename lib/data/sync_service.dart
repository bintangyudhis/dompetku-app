import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'budgets_api.dart';
import 'categories_api.dart';
import 'offline_cache.dart';
import 'summary_api.dart';
import 'transactions_api.dart';

/// Status sinkronisasi yang dibaca chip indikator di UI.
///
/// Aturan mainnya sederhana dan jujur: antrean diputar dari yang paling
/// lama dulu; satu operasi yang gagal menghentikan pemutaran (sisanya
/// menunggu percobaan berikut) supaya urutan perubahan tidak terbalik.
/// Daftar baru dari server selalu ditulis ke cache sesudah pemutaran,
/// jadi layar yang membaca cache tidak pernah menampilkan data yang
/// lebih tua dari antrean yang belum terkirim.
class SyncService extends ChangeNotifier {
  SyncService({
    OfflineCache? cache,
    ApiClient? client,
    TransactionsApi? transactionsApi,
    CategoriesApi? categoriesApi,
    BudgetsApi? budgetsApi,
    SummaryApi? summaryApi,
  }) : _cache = cache ?? OfflineCache(),
       _client = client ?? ApiClient(),
       _transactionsApi = transactionsApi ?? TransactionsApi(),
       _categoriesApi = categoriesApi ?? CategoriesApi(),
       _budgetsApi = budgetsApi ?? BudgetsApi(),
       _summaryApi = summaryApi ?? SummaryApi();

  final OfflineCache _cache;
  final ApiClient _client;
  final TransactionsApi _transactionsApi;
  final CategoriesApi _categoriesApi;
  final BudgetsApi _budgetsApi;
  final SummaryApi _summaryApi;

  bool _syncing = false;
  DateTime? _lastSyncedAt;
  int _pendingCount = 0;
  String? _lastError;

  bool get syncing => _syncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  int get pendingCount => _pendingCount;
  String? get lastError => _lastError;

  Future<void> refresh() async {
    _pendingCount = await _cache.pendingCount();
    _lastSyncedAt = await _cache.lastSync();
    notifyListeners();
  }

  /// Putar antrean tertunda, lalu segarkan cache dari server.
  ///
  /// Mengembalikan true bila semua operasi terkirim dan daftar berhasil
  /// disegarkan; false bila ada yang gagal (pesan ada di [lastError]).
  Future<bool> sync(String token) async {
    if (_syncing) return false;
    _syncing = true;
    _lastError = null;
    notifyListeners();
    try {
      final ops = await _cache.pendingOps();
      for (final op in ops) {
        try {
          await _replay(token, op);
        } catch (e) {
          _lastError = e is ApiException
              ? e.message
              : 'Sinkronisasi tertunda. Coba lagi saat koneksi membaik.';
          break;
        }
        if (op.id != null) await _cache.removePending(op.id!);
      }
      if (_lastError != null) return false;

      final transactions = await _transactionsApi.list(
        token: token,
        limit: 200,
      );
      final categories = await _categoriesApi.list(token: token);
      final budgets = await _budgetsApi.list(token: token);
      final summary = await _summaryApi.fetch(token: token);
      await _cache.saveTransactions(transactions.map((t) => t.toJson()).toList());
      await _cache.saveCategories(categories.map((c) => c.toJson()).toList());
      await _cache.saveBudgets(budgets.map((b) => b.toJson()).toList());
      await _cache.saveSummary(summary.toJson());

      _lastSyncedAt = DateTime.now();
      await _cache.setLastSync(_lastSyncedAt!);
      _pendingCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e is ApiException
          ? e.message
          : 'Sinkronisasi gagal. Data cache tetap dipakai.';
      notifyListeners();
      return false;
    } finally {
      _syncing = false;
      _pendingCount = await _cache.pendingCount();
      notifyListeners();
    }
  }

  /// Memutar satu operasi tertunda lewat ApiClient mentah.
  ///
  /// Konvensi payload (ditulis state saat mutasi gagal): `id` untuk
  /// ubah/hapus, sisanya badan permintaan API. `budget_update` hanya
  /// membawa nominal, sesuai PATCH server.
  Future<void> _replay(String token, PendingOp op) async {
    final payload = Map<String, dynamic>.from(op.payload);
    final id = payload.remove('id') as String?;
    switch (op.kind) {
      case 'transaction_create':
        await _client.postJson(
          AppConfig.transactionsPath,
          payload,
          token: token,
        );
      case 'transaction_update':
        await _client.patchJson(
          '${AppConfig.transactionsPath}/$id',
          payload,
          token: token,
        );
      case 'transaction_delete':
        await _client.deleteJson(
          '${AppConfig.transactionsPath}/$id',
          token: token,
        );
      case 'category_create':
        await _client.postJson(
          AppConfig.categoriesPath,
          payload,
          token: token,
        );
      case 'category_update':
        await _client.patchJson(
          '${AppConfig.categoriesPath}/$id',
          payload,
          token: token,
        );
      case 'category_delete':
        await _client.deleteJson(
          '${AppConfig.categoriesPath}/$id',
          token: token,
        );
      case 'budget_create':
        await _client.postJson(AppConfig.budgetsPath, payload, token: token);
      case 'budget_update':
        await _client.patchJson(
          '${AppConfig.budgetsPath}/$id',
          {'amount': payload['amount']},
          token: token,
        );
      case 'budget_delete':
        await _client.deleteJson('${AppConfig.budgetsPath}/$id', token: token);
      default:
        throw const ApiException('Operasi tertunda tidak dikenali.');
    }
  }
}

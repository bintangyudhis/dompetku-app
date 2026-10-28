import 'package:flutter/foundation.dart' hide Summary;

import '../data/api_exception.dart';
import '../data/models/summary.dart';
import '../data/models/transaction.dart';
import '../data/offline_cache.dart';
import '../data/summary_api.dart';
import '../data/transactions_api.dart';

/// Total pengeluaran satu hari, dipakai grafik 7 hari di dasbor.
class DailyTotal {
  const DailyTotal({required this.date, required this.total});

  final DateTime date;
  final int total;
}

/// State dasbor: ringkasan + transaksi terbaru + agregat 7 hari.
///
/// Muat ulang lewat [load] (dipanggil saat layar dibuka dan saat
/// pull-to-refresh); galat jaringan disimpan di [error], bukan dilempar.
class DashboardState extends ChangeNotifier {
  DashboardState({
    SummaryApi? summaryApi,
    TransactionsApi? transactionsApi,
    OfflineCache? cache,
  }) : _summaryApi = summaryApi ?? SummaryApi(),
       _transactionsApi = transactionsApi ?? TransactionsApi(),
       _cache = cache ?? OfflineCache();

  final SummaryApi _summaryApi;
  final TransactionsApi _transactionsApi;
  final OfflineCache _cache;

  bool _loading = false;
  String? _error;
  bool _fromCache = false;
  Summary? _summary;
  List<TransactionItem> _recent = [];

  bool get loading => _loading;
  String? get error => _error;

  /// True bila ringkasan yang tampil berasal dari cache (jaringan gagal).
  bool get fromCache => _fromCache;

  Summary? get summary => _summary;
  List<TransactionItem> get recent => _recent;

  /// Transaksi terbaru, paling banyak 5 — sisanya ada di layar Transaksi.
  List<TransactionItem> get recentFive => _recent.take(5).toList();

  /// Pengeluaran per hari selama 7 hari terakhir (termasuk hari ini),
  /// dihitung dari transaksi yang sudah dimuat — data asli, bukan contoh.
  List<DailyTotal> get lastSevenDaysExpense {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final total = _recent
          .where((t) => !t.isIncome && _sameDay(t.date, day))
          .fold<int>(0, (sum, t) => sum + t.amount);
      return DailyTotal(date: day, total: total);
    });
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load(String token) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _fromCache = false;
    notifyListeners();
    try {
      final results = await Future.wait([
        _summaryApi.fetch(token: token),
        _transactionsApi.list(token: token, limit: 100),
      ]);
      _summary = results[0] as Summary;
      _recent = results[1] as List<TransactionItem>;
      await _cache.saveSummary(_summary!.toJson());
      await _cache.saveTransactions(_recent.map((t) => t.toJson()).toList());
    } catch (e) {
      if (e is ApiException) {
        final cachedSummary = await _cache.loadSummary();
        final cachedTransactions = await _cache.loadTransactions();
        if (cachedSummary != null && cachedTransactions.isNotEmpty) {
          _summary = Summary.fromJson(cachedSummary);
          _recent = cachedTransactions.map(TransactionItem.fromJson).toList();
          _fromCache = true;
          _error = null;
        } else {
          _error = e.message;
        }
      } else {
        _error = 'Gagal memuat dasbor. Coba lagi.';
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

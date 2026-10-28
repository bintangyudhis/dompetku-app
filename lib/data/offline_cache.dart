import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Satu perubahan yang gagal terkirim karena tidak ada koneksi, menunggu
/// giliran sinkronisasi. `payload` adalah badan permintaan API-nya, jadi
/// pemutaran ulang tidak butuh bentuk data lain.
class PendingOp {
  const PendingOp({this.id, required this.kind, required this.payload});

  final int? id;
  final String kind;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {'kind': kind, 'payload': payload};

  factory PendingOp.fromJson(Map<String, dynamic> json) => PendingOp(
    kind: json['kind'] as String,
    payload: (json['payload'] as Map<String, dynamic>?) ?? {},
  );
}

/// Cache lokal (sqflite) untuk pemakaian offline.
///
/// Isinya adalah salinan terakhir yang berhasil diambil dari server:
/// daftar transaksi, kategori, budget, dan ringkasan. Bila jaringan gagal,
/// layar membaca dari sini dan menandai datanya sebagai cache. Perubahan
/// yang gagal terkirim disimpan di antrean [PendingOp] untuk diputar ulang
/// saat sinkronisasi, bukan dibuang diam-diam.
class OfflineCache {
  OfflineCache({Future<Database> Function()? databaseFactory})
    : _databaseFactory = databaseFactory;

  final Future<Database> Function()? _databaseFactory;
  Database? _db;

  static const _dbName = 'dompetku_cache.db';

  Future<Database> get _database async {
    if (_db != null) return _db!;
    if (_databaseFactory != null) {
      _db = await _databaseFactory!();
      return _db!;
    }
    final path = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE items(kind TEXT NOT NULL, id TEXT NOT NULL, '
          'payload TEXT NOT NULL, PRIMARY KEY(kind, id))',
        );
        await db.execute(
          'CREATE TABLE kv(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE pending_ops(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'kind TEXT NOT NULL, payload TEXT NOT NULL, '
          'created_at INTEGER NOT NULL)',
        );
      },
    );
    return _db!;
  }

  Future<void> _saveItems(
    String kind,
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic>) idOf,
  ) async {
    final db = await _database;
    final batch = db.batch();
    batch.delete('items', where: 'kind = ?', whereArgs: [kind]);
    for (final item in items) {
      batch.insert('items', {
        'kind': kind,
        'id': idOf(item),
        'payload': jsonEncode(item),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> _loadItems(String kind) async {
    final db = await _database;
    final rows = await db.query(
      'items',
      where: 'kind = ?',
      whereArgs: [kind],
    );
    return rows
        .map((r) => jsonDecode(r['payload'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> saveTransactions(List<Map<String, dynamic>> items) =>
      _saveItems('transaction', items, (e) => e['id'] as String);

  Future<List<Map<String, dynamic>>> loadTransactions() =>
      _loadItems('transaction');

  Future<void> saveCategories(List<Map<String, dynamic>> items) =>
      _saveItems('category', items, (e) => e['id'] as String);

  Future<List<Map<String, dynamic>>> loadCategories() =>
      _loadItems('category');

  Future<void> saveBudgets(List<Map<String, dynamic>> items) =>
      _saveItems('budget', items, (e) => e['id'] as String);

  Future<List<Map<String, dynamic>>> loadBudgets() => _loadItems('budget');

  Future<void> saveSummary(Map<String, dynamic> summary) async {
    final db = await _database;
    await db.insert('kv', {
      'key': 'summary',
      'value': jsonEncode(summary),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loadSummary() async {
    final db = await _database;
    final rows = await db.query(
      'kv',
      where: 'key = ?',
      whereArgs: ['summary'],
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['value'] as String) as Map<String, dynamic>;
  }

  Future<void> setLastSync(DateTime at) async {
    final db = await _database;
    await db.insert('kv', {
      'key': 'last_sync',
      'value': at.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DateTime?> lastSync() async {
    final db = await _database;
    final rows = await db.query(
      'kv',
      where: 'key = ?',
      whereArgs: ['last_sync'],
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value'] as String);
  }

  Future<void> enqueuePending(String kind, Map<String, dynamic> payload) async {
    final db = await _database;
    await db.insert('pending_ops', {
      'kind': kind,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<PendingOp>> pendingOps() async {
    final db = await _database;
    final rows = await db.query('pending_ops', orderBy: 'created_at ASC');
    return rows
        .map(
          (r) => PendingOp(
            id: r['id'] as int?,
            kind: r['kind'] as String,
            payload:
                jsonDecode(r['payload'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> removePending(int id) async {
    final db = await _database;
    await db.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> pendingCount() async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM pending_ops');
    return (rows.first['n'] as int?) ?? 0;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

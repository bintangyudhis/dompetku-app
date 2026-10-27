import '../config/app_config.dart';
import 'api_client.dart';
import 'models/transaction.dart';

/// Lapisan API transaksi: daftar, tambah, ubah, hapus.
///
/// Ubah/hapus memakai endpoint PATCH/DELETE
/// /api/public/transactions/[id] di dompetku-web (ditambahkan Day 9);
/// daftar memakai ?type= & ?limit= yang sudah ada di server.
class TransactionsApi {
  TransactionsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<TransactionItem>> list({
    required String token,
    String? type,
    int limit = 100,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (type != null) query['type'] = type;
    final path = Uri(
      path: AppConfig.transactionsPath,
      queryParameters: query,
    ).toString();
    final json = await _client.getJson(path, token: token);
    final items = json['transactions'] as List<dynamic>;
    return items
        .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionItem> create({
    required String token,
    required TransactionItem draft,
  }) async {
    final json = await _client.postJson(
      AppConfig.transactionsPath,
      draft.toRequestJson(),
      token: token,
    );
    return TransactionItem.fromJson(json['transaction'] as Map<String, dynamic>);
  }

  Future<TransactionItem> update({
    required String token,
    required TransactionItem item,
  }) async {
    final json = await _client.patchJson(
      '${AppConfig.transactionsPath}/${item.id}',
      item.toRequestJson(),
      token: token,
    );
    return TransactionItem.fromJson(json['transaction'] as Map<String, dynamic>);
  }

  Future<void> delete({required String token, required String id}) async {
    await _client.deleteJson(
      '${AppConfig.transactionsPath}/$id',
      token: token,
    );
  }
}

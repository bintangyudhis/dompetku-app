import '../config/app_config.dart';
import 'api_client.dart';
import 'models/budget.dart';

/// Lapisan API budget: daftar bulan berjalan, buat/ubah, hapus.
///
/// Buat memakai POST upsert server (satu budget per kategori per bulan),
/// jadi "tambah" dan "ubah nominal" untuk kategori yang sama adalah
/// operasi yang sama di sisi server; ubah lewat PATCH memakai id budget.
class BudgetsApi {
  BudgetsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Budget>> list({
    required String token,
    int? month,
    int? year,
  }) async {
    final query = <String, String>{};
    if (month != null) query['month'] = '$month';
    if (year != null) query['year'] = '$year';
    final path = query.isEmpty
        ? AppConfig.budgetsPath
        : Uri(
            path: AppConfig.budgetsPath,
            queryParameters: query,
          ).toString();
    final json = await _client.getJson(path, token: token);
    final items = json['budgets'] as List<dynamic>;
    return items
        .map((e) => Budget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Budget> create({required String token, required Budget draft}) async {
    final json = await _client.postJson(
      AppConfig.budgetsPath,
      draft.toRequestJson(),
      token: token,
    );
    return Budget.fromJson(json['budget'] as Map<String, dynamic>);
  }

  Future<Budget> update({required String token, required Budget budget}) async {
    final json = await _client.patchJson(
      '${AppConfig.budgetsPath}/${budget.id}',
      {'amount': budget.amount},
      token: token,
    );
    return Budget.fromJson(json['budget'] as Map<String, dynamic>);
  }

  Future<void> delete({required String token, required String id}) async {
    await _client.deleteJson('${AppConfig.budgetsPath}/$id', token: token);
  }
}

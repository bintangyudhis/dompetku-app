import '../config/app_config.dart';
import 'api_client.dart';
import 'models/app_category.dart';

/// Lapisan API kategori: satu GET, disaring per tipe bila diminta.
class CategoriesApi {
  CategoriesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<AppCategory>> list({required String token, String? type}) async {
    final path = type == null
        ? AppConfig.categoriesPath
        : Uri(
            path: AppConfig.categoriesPath,
            queryParameters: {'type': type},
          ).toString();
    final json = await _client.getJson(path, token: token);
    final items = json['categories'] as List<dynamic>;
    return items
        .map((e) => AppCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Buat kategori (POST /api/public/categories, ditambahkan Day 10).
  Future<AppCategory> create({
    required String token,
    required AppCategory draft,
  }) async {
    final json = await _client.postJson(
      AppConfig.categoriesPath,
      draft.toRequestJson(),
      token: token,
    );
    return AppCategory.fromJson(json['category'] as Map<String, dynamic>);
  }

  /// Ubah kategori (PATCH /api/public/categories/[id]).
  Future<AppCategory> update({
    required String token,
    required AppCategory category,
  }) async {
    final json = await _client.patchJson(
      '${AppConfig.categoriesPath}/${category.id}',
      category.toRequestJson(),
      token: token,
    );
    return AppCategory.fromJson(json['category'] as Map<String, dynamic>);
  }

  /// Hapus kategori; server menolak bila masih dipakai transaksi.
  Future<void> delete({required String token, required String id}) async {
    await _client.deleteJson('${AppConfig.categoriesPath}/$id', token: token);
  }
}

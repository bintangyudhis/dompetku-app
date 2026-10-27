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
}

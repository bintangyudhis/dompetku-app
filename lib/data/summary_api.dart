import '../config/app_config.dart';
import 'api_client.dart';
import 'models/summary.dart';

/// Lapisan API ringkasan: satu GET, dipakai dasbor.
class SummaryApi {
  SummaryApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Summary> fetch({required String token}) async {
    final json = await _client.getJson(AppConfig.summaryPath, token: token);
    return Summary.fromJson(json);
  }
}

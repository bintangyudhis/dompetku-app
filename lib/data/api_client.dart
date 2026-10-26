import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Klien HTTP tipis untuk dompetku-web: hanya POST JSON + parsing galat.
/// Pesan galat server (kolom `error`) diteruskan apa adanya ke UI.
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.baseUrl;

  final http.Client _http;
  final String _baseUrl;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    late final http.Response response;
    try {
      response = await _http.post(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error'] as String?
          : null;
      throw ApiException(
        message ?? 'Server mengembalikan galat (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons server tidak dikenali.');
    }
    return decoded;
  }
}

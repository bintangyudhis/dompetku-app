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

  /// GET dengan Bearer opsional. Dipakai layar dasbor & transaksi.
  Future<Map<String, dynamic>> getJson(String path, {String? token}) async {
    final decoded = await _request('GET', path, token: token);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons server tidak dikenali.');
    }
    return decoded;
  }

  /// PATCH JSON dengan Bearer. Dipakai ubah transaksi.
  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final decoded = await _request('PATCH', path, body: body, token: token);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons server tidak dikenali.');
    }
    return decoded;
  }

  /// DELETE dengan Bearer. Badan kosong (204) dianggap sukses.
  Future<void> deleteJson(String path, {String? token}) async {
    await _request('DELETE', path, token: token);
  }

  /// Satu jalur permintaan GET/PATCH/DELETE: header, galat jaringan,
  /// dan pesan galat server (kolom `error`) ditangani di satu tempat.
  /// Badan kosong (mis. 204) menghasilkan map kosong, bukan galat parse.
  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    late final http.Response response;
    try {
      final uri = Uri.parse('$_baseUrl$path');
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers);
        case 'PATCH':
          response = await _http.patch(
            uri,
            headers: headers,
            body: jsonEncode(body),
          );
        case 'DELETE':
          response = await _http.delete(uri, headers: headers);
        default:
          throw const ApiException('Metode HTTP tidak didukung.');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{};
      }
      throw ApiException(
        'Server mengembalikan galat (${response.statusCode}).',
        statusCode: response.statusCode,
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
    return decoded;
  }
}

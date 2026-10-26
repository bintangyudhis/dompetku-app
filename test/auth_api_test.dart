import 'dart:convert';

import 'package:dompetku_app/data/api_client.dart';
import 'package:dompetku_app/data/api_exception.dart';
import 'package:dompetku_app/data/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('login mengembalikan sesi dari respons server', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/public/auth/login');
      return http.Response(
        jsonEncode({
          'token': 'token-contoh',
          'user': {'id': 'u1', 'name': 'Bintang', 'email': 'a@b.co'},
        }),
        200,
      );
    });
    final api = AuthApi(
      client: ApiClient(httpClient: client, baseUrl: 'https://contoh.test'),
    );
    final session = await api.login(email: 'a@b.co', password: 'rahasia');
    expect(session.token, 'token-contoh');
    expect(session.user.name, 'Bintang');
  });

  test('galat server diteruskan sebagai pesan ApiException', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({'error': 'Email atau kata sandi salah.'}),
        401,
      );
    });
    final api = AuthApi(
      client: ApiClient(httpClient: client, baseUrl: 'https://contoh.test'),
    );
    expect(
      () => api.login(email: 'a@b.co', password: 'salah'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Email atau kata sandi salah.',
        ),
      ),
    );
  });
}

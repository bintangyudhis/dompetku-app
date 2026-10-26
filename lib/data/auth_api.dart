import '../config/app_config.dart';
import 'api_client.dart';
import 'models/auth_session.dart';

/// Lapisan API autentikasi: login & register memakai akun web yang sama.
/// Register yang sukses langsung mengembalikan sesi (tidak perlu login ulang),
/// persis seperti perilaku endpoint web-nya.
class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.postJson(AppConfig.loginPath, {
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _client.postJson(AppConfig.registerPath, {
      'name': name,
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }
}

import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/auth_api.dart';
import '../data/token_storage.dart';
import '../data/models/auth_session.dart';

/// Status sesi aplikasi, dipakai auth guard untuk memilih layar.
enum AuthStatus { initializing, unauthenticated, authenticated }

/// State autentikasi: memulihkan sesi tersimpan saat aplikasi dibuka,
/// lalu login / register / logout. Satu-satunya tempat yang memegang token.
class AuthState extends ChangeNotifier {
  AuthState({AuthApi? authApi, TokenStorage? tokenStorage})
    : _authApi = authApi ?? AuthApi(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.initializing;
  AuthSession? _session;
  String? _error;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> restore() async {
    final saved = await _tokenStorage.readSession();
    if (saved != null) {
      _session = saved;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _run(() => _authApi.login(email: email, password: password));
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _run(
      () => _authApi.register(name: name, email: email, password: password),
    );
  }

  Future<bool> _run(Future<AuthSession> Function() call) async {
    _error = null;
    notifyListeners();
    try {
      final session = await call();
      await _tokenStorage.saveSession(session);
      _session = session;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e is ApiException ? e.message : 'Terjadi galat tak terduga.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _session = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

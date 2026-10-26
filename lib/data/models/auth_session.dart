import 'app_user.dart';

/// Sesi login: token JWT dari server + data pengguna yang bersangkutan.
/// Token inilah yang dikirim sebagai `Authorization: Bearer <token>` pada
/// setiap permintaan berikutnya — bukan API key buatan pengguna.
class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token'] as String,
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}

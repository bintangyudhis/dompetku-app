/// Konfigurasi aplikasi DompetKu.
///
/// Aplikasi ini tidak punya database sendiri: semua data tinggal di
/// dompetku-web dan diakses lewat endpoint publiknya. Ganti [baseUrl] bila
/// server web dipindah (mis. ke subdomain sendiri).
class AppConfig {
  AppConfig._();

  /// URL dasar dompetku-web (produksi).
  static const String baseUrl = 'https://dompetku-web-lake.vercel.app';

  /// Endpoint login aplikasi (POST { email, password }).
  static const String loginPath = '/api/public/auth/login';

  /// Endpoint register aplikasi (POST { name, email, password }).
  static const String registerPath = '/api/public/auth/register';
}

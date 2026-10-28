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

  /// Ringkasan keuangan (GET, butuh Bearer).
  static const String summaryPath = '/api/public/summary';

  /// Daftar & catat transaksi (GET/POST, butuh Bearer).
  static const String transactionsPath = '/api/public/transactions';

  /// Daftar kategori (GET, butuh Bearer; saring dengan ?type=).
  static const String categoriesPath = '/api/public/categories';

  /// Daftar & kelola budget bulan berjalan (GET/POST/PATCH/DELETE,
  /// butuh Bearer; ditambahkan Day 10 di dompetku-web).
  static const String budgetsPath = '/api/public/budgets';
}

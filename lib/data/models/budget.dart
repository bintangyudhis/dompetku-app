/// Satu budget kategori untuk satu bulan, dari GET /api/public/budgets.
///
/// Server sudah menghitung realisasi (`spent`, `persen`, `sisa`,
/// `status`); aplikasi hanya membaca angka itu, bukan menghitung ulang
/// dari transaksi, supaya yang tampil sama persis dengan web.
class Budget {
  const Budget({
    required this.id,
    required this.amount,
    required this.month,
    required this.year,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.spent,
    required this.percent,
    required this.remaining,
    required this.status,
  });

  final String id;
  final int amount;
  final int month;
  final int year;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final int spent;
  final int percent;
  final int remaining;
  final String status;

  bool get isOver => status == 'LEWAT';
  bool get isWarning => status == 'WASPADA';

  /// Rasio 0.0–1.0 untuk bilah progres; dibatasi 1.0 bila sudah lewat.
  double get progressRatio {
    if (amount <= 0) return 0;
    final ratio = spent / amount;
    return ratio > 1 ? 1 : ratio;
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final amount = (json['amount'] as num).toInt();
    final spent = (json['spent'] as num?)?.toInt() ?? 0;
    // Respons buat/ubah (upsert) tidak membawa realisasi: turunkan dari
    // nominal supaya kartu tidak tampil sisa Rp0 sesaat setelah simpan.
    return Budget(
      id: json['id'] as String,
      amount: amount,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      categoryId: (category?['id'] ?? json['categoryId']) as String,
      categoryName: (category?['name'] ?? '') as String,
      categoryIcon: category?['icon'] as String?,
      spent: spent,
      percent: (json['persen'] as num?)?.toInt() ??
          (amount > 0 ? (spent * 100 / amount).round() : 0),
      remaining: (json['sisa'] as num?)?.toInt() ?? amount - spent,
      status: json['status'] as String? ?? 'AMAN',
    );
  }

  /// Badan POST / PATCH: server memakai upsert per (kategori, bulan,
  /// tahun) untuk buat, dan nominal saja untuk ubah.
  Map<String, dynamic> toRequestJson() => {
    'categoryId': categoryId,
    'amount': amount,
    'month': month,
    'year': year,
  };
}

/// Satu transaksi dari dompetku-web: nominal, tipe, kategori, tanggal.
///
/// `type` di server memakai string `INCOME` / `EXPENSE`; aplikasi
/// menyimpannya apa adanya supaya tidak ada pemetaan yang bisa meleset.
class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.note,
  });

  final String id;
  final int amount;
  final String type;
  final DateTime date;
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? note;

  bool get isIncome => type == 'INCOME';

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return TransactionItem(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      categoryId: (category?['id'] ?? json['categoryId']) as String,
      categoryName: (category?['name'] ?? '') as String,
      categoryIcon: category?['icon'] as String?,
      note: json['note'] as String?,
    );
  }

  /// Bentuk lengkap untuk cache offline: dibaca lagi lewat fromJson.
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'date': date.toIso8601String(),
    'category': {
      'id': categoryId,
      'name': categoryName,
      'icon': categoryIcon,
    },
    'note': note,
  };

  /// Badan permintaan POST / PATCH: hanya kolom yang diterima server.
  Map<String, dynamic> toRequestJson() => {
    'amount': amount,
    'type': type,
    'categoryId': categoryId,
    'note': note ?? '',
    'date': date.toIso8601String(),
  };
}

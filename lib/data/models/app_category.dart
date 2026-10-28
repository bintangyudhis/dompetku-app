/// Kategori dari GET /api/public/categories: dipakai dropdown formulir
/// transaksi dan disaring per tipe (pemasukan / pengeluaran).
class AppCategory {
  const AppCategory({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
  });

  final String id;
  final String name;
  final String type;
  final String? icon;

  bool get isIncome => type == 'INCOME';

  factory AppCategory.fromJson(Map<String, dynamic> json) => AppCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    icon: json['icon'] as String?,
  );

  /// Badan POST / PATCH: hanya kolom yang diterima server.
  Map<String, dynamic> toRequestJson() => {
    'name': name,
    'type': type,
    'icon': icon ?? '💰',
  };
}

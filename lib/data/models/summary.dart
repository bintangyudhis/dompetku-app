/// Ringkasan dari GET /api/public/summary: saldo total plus
/// pemasukan/pengeluaran bulan berjalan (zona waktu server, Jakarta).
class Summary {
  const Summary({
    required this.saldo,
    required this.pemasukanBulanIni,
    required this.pengeluaranBulanIni,
    required this.year,
    required this.month,
  });

  final int saldo;
  final int pemasukanBulanIni;
  final int pengeluaranBulanIni;
  final int year;
  final int month;

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    saldo: (json['saldo'] as num).toInt(),
    pemasukanBulanIni: (json['pemasukanBulanIni'] as num).toInt(),
    pengeluaranBulanIni: (json['pengeluaranBulanIni'] as num).toInt(),
    year: json['year'] as int,
    month: json['month'] as int,
  );
}

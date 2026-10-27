/// Format rupiah & tanggal tanpa dependensi intl: pemisah ribuan titik,
/// nama bulan Indonesia, cukup untuk seluruh UI aplikasi.

String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign${buffer}';
}

const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// "27 Okt 2026" — dipakai daftar transaksi.
String formatTanggal(DateTime date) =>
    '${date.day} ${_bulan[date.month - 1]} ${date.year}';

/// "Sen" dkk. untuk label grafik 7 hari.
String hariSingkat(DateTime date) =>
    const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][date.weekday - 1];

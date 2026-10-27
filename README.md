# DompetKu App

DompetKu App adalah aplikasi Flutter pencatat keuangan pribadi. Aplikasi ini tidak memiliki database sendiri. Semua data disimpan oleh dompetku-web dan diakses lewat REST API publiknya dengan akun yang sama seperti versi web.

Repositori server: https://github.com/bintangyudhis/dompetku-web

## Fitur

- Login dan registrasi dengan email dan kata sandi yang sama seperti versi web.
- Token sesi JWT berlaku 30 hari dan tersimpan di penyimpanan aman perangkat memakai flutter_secure_storage.
- Dasbor berisi saldo, pemasukan dan pengeluaran bulan berjalan, grafik batang pengeluaran 7 hari terakhir, dan transaksi terbaru.
- Pull to refresh untuk memuat ulang data dasbor.
- Daftar transaksi dengan pencarian berdasarkan catatan atau kategori dan filter pemasukan atau pengeluaran.
- Tambah, ubah, dan hapus transaksi. Hapus memakai dialog konfirmasi dan formulir memeriksa nominal serta kategori sebelum data dikirim.
- Format angka rupiah dan tanggal dalam Bahasa Indonesia.

## Teknologi

- Flutter dengan Dart SDK ^3.13.7
- http untuk panggilan API
- provider untuk manajemen state
- flutter_secure_storage untuk penyimpanan token
- fl_chart untuk grafik dasbor

## Cara Instalasi

Prasyarat:

- Flutter SDK sesuai batas versi di `pubspec.yaml`
- Emulator atau perangkat Android atau iOS
- Server dompetku-web yang berjalan, lokal atau produksi

Langkah instalasi:

```bash
git clone https://github.com/bintangyudhis/dompetku-app.git
cd dompetku-app
flutter pub get
```

Alamat server diatur di berkas `lib/config/app_config.dart` pada konstanta `baseUrl`. Nilai bawaan menunjuk ke server produksi dompetku-web. Ganti nilai itu bila server dipindah atau dijalankan lokal.

## Cara Menjalankan

```bash
flutter run
```

Pemeriksaan kode dan pengujian:

```bash
flutter analyze
flutter test
```

## Lisensi

Proyek ini memakai lisensi MIT. Lihat berkas [LICENSE](LICENSE).

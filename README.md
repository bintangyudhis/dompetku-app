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
- Kategori bisa ditambah, diubah, dan dihapus dari tab Kategori, dipisah per tipe pemasukan dan pengeluaran. Hapus ditolak server bila kategori masih dipakai transaksi.
- Anggaran bulan berjalan di tab Anggaran: batas per kategori pengeluaran, progres terpakai, dan penanda mendekati batas (80 persen) serta lewat batas (100 persen). Tambah memakai upsert server, jadi satu kategori hanya punya satu budget per bulan.
- Format angka rupiah dan tanggal dalam Bahasa Indonesia.

## Mode offline dan sinkronisasi

- Daftar transaksi, kategori, budget, dan ringkasan terakhir yang berhasil diambil tersimpan di cache lokal (sqflite). Bila jaringan gagal, layar menampilkan data cache dengan spanduk "data offline".
- Perubahan yang gagal terkirim karena tidak ada koneksi tidak dibuang: perubahan masuk antrean lokal dan diputar ulang dari yang paling lama saat sinkronisasi. Galat server (misalnya nominal tidak valid) tidak masuk antrean, melainkan ditampilkan sebagai pesan galat.
- Chip status di atas layar menunjukkan keadaan sinkronisasi: sedang menyinkronkan, jumlah perubahan yang menunggu, gagal, atau jam terakhir tersinkron. Mengetuk chip menjalankan sinkronisasi lalu memuat ulang semua layar bila berhasil.
- Angka antrean pada chip diperbarui tiap pindah tab dan tiap aplikasi dibuka.

## Teknologi

- Flutter dengan Dart SDK ^3.13.7
- http untuk panggilan API
- provider untuk manajemen state
- flutter_secure_storage untuk penyimpanan token
- fl_chart untuk grafik dasbor
- sqflite untuk cache offline dan antrean sinkronisasi

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

## Build APK

APK rilis Android dibuat dari root proyek:

```bash
flutter build apk --release
```

Berkas hasil build ada di `build/app/outputs/flutter-apk/app-release.apk`. Pasang berkas itu langsung ke perangkat Android, atau pakai varian per arsitektur (`flutter build apk --release --split-per-abi`) bila ukuran berkas jadi perhatian. Tanda tangan rilis memakai keystore pengembang: atur `key.properties` di folder `android` sebelum build distribusi, jangan commit keystore atau kata sandinya.

## Lisensi

Proyek ini memakai lisensi MIT. Lihat berkas [LICENSE](LICENSE).

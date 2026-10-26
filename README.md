# DompetKu App

Aplikasi Flutter pencatat keuangan pribadi. Aplikasi ini tidak punya database
sendiri — semua data tinggal di **dompetku-web** dan diakses lewat endpoint
publiknya, dengan akun yang sama seperti di web.

## Autentikasi

- Login: `POST /api/public/auth/login` dengan `{ email, password }`.
- Register: `POST /api/public/auth/register` dengan
  `{ name, email, password }` (nama 2–80 karakter, kata sandi 6–72 karakter).
- Keduanya mengembalikan `{ token, user }`: token sesi JWT (30 hari) yang
  dikirim sebagai `Authorization: Bearer <token>`.
- Token disimpan di secure storage perangkat (`flutter_secure_storage`),
  bukan di penyimpanan biasa. Tidak ada API key buatan pengguna.
- Server default: `https://dompetku-web-lake.vercel.app`
  (lihat `lib/config/app_config.dart`).

## Menjalankan

```sh
flutter pub get
flutter run
```

Periksa kode sebelum commit:

```sh
flutter analyze
flutter test
```

## Build APK

```sh
flutter build apk --release
```

Berkas APK ada di `build/app/outputs/flutter-apk/app-release.apk`.

## Struktur

```text
lib/
  main.dart            # entry point
  app.dart             # root + auth guard (splash / login / beranda)
  config/              # URL dasar & endpoint API
  theme/               # tema Material 3 DompetKu
  data/                # ApiClient, AuthApi, model, secure storage
  state/               # AuthState (ChangeNotifier)
  widgets/             # kolom input, tombol utama, kerangka layar auth
  screens/             # splash, login, register, beranda
test/
  auth_api_test.dart   # parsing sesi & pesan galat login
```

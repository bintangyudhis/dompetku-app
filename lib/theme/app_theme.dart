import 'package:flutter/material.dart';

/// Tema DompetKu: satu aksen hijau tua yang tenang di atas kertas hangat,
/// tanpa gradasi dan tanpa warna-warni per kartu. Hierarki dibangun dari
/// ukuran dan ruang, bukan dari pewarnaan kata per kata.
class AppTheme {
  AppTheme._();

  static const Color ink = Color(0xFF1C2420);
  static const Color paper = Color(0xFFFAF6EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryGreen = Color(0xFF175E3D);
  static const Color muted = Color(0xFF6B7280);

  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: primaryGreen,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8D2C4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8D2C4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryGreen),
      ),
    );
  }
}

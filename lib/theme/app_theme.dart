import 'package:flutter/material.dart';

/// Palet & tema aplikasi — diambil dari desain Figma "Kasir_Desain".
class AppColors {
  AppColors._();

  // Merah utama (brand)
  static const red = Color(0xFFE51D2A);
  static const redBright = Color(0xFFEF2A39); // tombol / FAB
  static const redDeep = Color(0xFFCA101C); // ujung gradien
  static const redSoft = Color(0xFFFB5767); // pangkal gradien

  // Netral
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF3F4F6);
  static const chipBg = Color(0xFFF5F5F5);
  static const line = Color(0xFFE9E9EE);

  // Teks
  static const ink = Color(0xFF141417);
  static const inkSoft = Color(0xFF374957);
  static const textMuted = Color(0xFF8E8E8E);
  static const textFaint = Color(0xFF928989);
  static const chipText = Color(0xFF6A6A6A);

  // Semantik (dipertahankan)
  static const success = Color(0xFF34A853);
  static const warning = Color(0xFFFBBC05);
  static const danger = Color(0xFFE51D2A);

  // Gradien login
  static const loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [redSoft, redDeep],
  );

  // Bayangan lembut untuk kartu / search pill
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.red,
    primary: AppColors.red,
  ).copyWith(surface: AppColors.bg);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Poppins',
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.apply(
      fontFamily: 'Poppins',
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: AppColors.ink,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

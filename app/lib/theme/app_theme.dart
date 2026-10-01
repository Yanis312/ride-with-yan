import 'package:flutter/material.dart';

/// Couleurs de la marque, reprises du logo (branding/icon.svg).
abstract final class AppColors {
  static const night = Color(0xFF11203A);
  static const nightLight = Color(0xFF16263D);
  static const nightDark = Color(0xFF0B1422);
  static const amber = Color(0xFFF5B700);
  static const text = Color(0xFFF2F4F8);
  static const textMuted = Color(0xFF9AA6BA);
  static const surface = Color(0xFF1B2D47);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.amber,
    brightness: Brightness.dark,
    primary: AppColors.amber,
    onPrimary: AppColors.nightDark,
    surface: AppColors.night,
    onSurface: AppColors.text,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.nightDark,
    useMaterial3: true,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.amber,
      contentTextStyle: TextStyle(
        color: AppColors.nightDark,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),
  );
}

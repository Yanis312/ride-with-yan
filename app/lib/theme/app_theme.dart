import 'package:flutter/material.dart';

/// Palette "noir profond + or" (recommandation ui-ux-pro-max pour un service
/// de chauffeur haut de gamme), alignée sur l'ambre du logo.
abstract final class AppColors {
  static const ink = Color(0xFF07080B);
  static const inkRaised = Color(0xFF0E1117);
  static const night = Color(0xFF11203A);
  static const gold = Color(0xFFF5B700);
  static const goldSoft = Color(0xFFE9C46A);
  static const text = Color(0xFFF4F1EA);
  static const textMuted = Color(0xFF9C9A94);

  /// Verre : surfaces translucides et filets d'un pixel.
  static const glass = Color(0x0AFFFFFF);
  static const hairline = Color(0x14FFFFFF);
  static const highlight = Color(0x1FFFFFFF);
}

abstract final class AppFonts {
  static const display = 'Cormorant';
  static const sans = 'Jakarta';
}

/// Courbes "à ressort" : jamais de linear ni d'ease-in-out par défaut.
abstract final class AppMotion {
  static const spring = Cubic(0.32, 0.72, 0, 1);
  static const emphasized = Cubic(0.16, 1, 0.3, 1);
  static const fast = Duration(milliseconds: 220);
  static const medium = Duration(milliseconds: 480);
  static const slow = Duration(milliseconds: 900);
}

abstract final class AppText {
  static const eyebrow = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.6,
    color: AppColors.goldSoft,
  );

  static TextStyle display(
    double size, {
    FontStyle style = FontStyle.normal,
    Color color = AppColors.text,
  }) => TextStyle(
    fontFamily: AppFonts.display,
    fontSize: size,
    fontWeight: FontWeight.w500,
    fontStyle: style,
    height: 1.0,
    letterSpacing: -0.5,
    color: color,
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textMuted,
  }) => TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: size,
    fontWeight: weight,
    height: 1.45,
    color: color,
  );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.dark,
    primary: AppColors.gold,
    onPrimary: AppColors.ink,
    surface: AppColors.ink,
    onSurface: AppColors.text,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
    fontFamily: AppFonts.sans,
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.inkRaised,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: AppColors.hairline),
      ),
      contentTextStyle: AppText.body(
        16,
        weight: FontWeight.w500,
        color: AppColors.text,
      ),
    ),
  );
}

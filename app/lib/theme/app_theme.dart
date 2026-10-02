import 'package:flutter/material.dart';

/// Couleur de marque (le Y du logo), identique dans les deux modes.
abstract final class Brand {
  static const gold = Color(0xFFF5B700);
  static const goldDeep = Color(0xFF8F6400);
  static const goldSoft = Color(0xFFF2CC5C);
  static const ink = Color(0xFF07080B);
}

/// Couleurs d'interface qui changent entre le mode clair et le mode sombre.
/// Clair : blanc cassé froid + noir cassé + une seule touche d'or (taste-skill :
/// pas de beige ni de crème par défaut, jamais de #000 ni de #FFF purs).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.text,
    required this.textMuted,
    required this.accentText,
    required this.glass,
    required this.hairline,
    required this.highlight,
    required this.coreTop,
    required this.coreBottom,
    required this.shadow,
  });

  final Color text;
  final Color textMuted;

  /// Or lisible en texte (plus foncé en mode clair pour le contraste).
  final Color accentText;
  final Color glass;
  final Color hairline;
  final Color highlight;
  final Color coreTop;
  final Color coreBottom;
  final Color shadow;

  static const dark = AppPalette(
    text: Color(0xFFF4F2EE),
    textMuted: Color(0xFFA3A3A8),
    accentText: Brand.goldSoft,
    glass: Color(0x0FFFFFFF),
    hairline: Color(0x1AFFFFFF),
    highlight: Color(0x26FFFFFF),
    coreTop: Color(0xD9161820),
    coreBottom: Color(0xE60B0C10),
    shadow: Color(0x00000000),
  );

  static const light = AppPalette(
    text: Color(0xFF0E1014),
    textMuted: Color(0xFF5B5F68),
    accentText: Brand.goldDeep,
    glass: Color(0x66FFFFFF),
    hairline: Color(0x1A0E1014),
    highlight: Color(0xCCFFFFFF),
    coreTop: Color(0xE6FFFFFF),
    coreBottom: Color(0xD9F4F6F9),
    shadow: Color(0x1A2B3550),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      coreTop: Color.lerp(coreTop, other.coreTop, t)!,
      coreBottom: Color.lerp(coreBottom, other.coreBottom, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
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
  static TextStyle eyebrow(Color color) => TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.6,
    color: color,
  );

  static TextStyle display(
    double size, {
    required Color color,
    FontStyle style = FontStyle.normal,
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
    required Color color,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: size,
    fontWeight: weight,
    height: 1.45,
    color: color,
  );
}

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final palette = dark ? AppPalette.dark : AppPalette.light;

  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Brand.gold,
      brightness: brightness,
      primary: Brand.gold,
      onPrimary: Brand.ink,
    ),
    scaffoldBackgroundColor: dark
        ? const Color(0xFF07080B)
        : const Color(0xFFF3F5F8),
    fontFamily: AppFonts.sans,
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: [palette],
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF15171D) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: palette.hairline),
      ),
      contentTextStyle: AppText.body(
        16,
        weight: FontWeight.w500,
        color: palette.text,
      ),
    ),
  );
}

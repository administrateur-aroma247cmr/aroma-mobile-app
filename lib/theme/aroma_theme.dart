import 'package:flutter/material.dart';

/// Couleurs proches du CRM (`frontend/src/index.css` + Tailwind zinc).
abstract final class AromaColors {
  static const canvas = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF030213);
  static const onPrimary = Color(0xFFFFFFFF);
  static const zinc900 = Color(0xFF18181B);
  static const zinc800 = Color(0xFF27272A);
  static const zinc500 = Color(0xFF71717A);
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc100 = Color(0xFFF4F4F5);
  static const inputFill = Color(0xFFF3F3F5);
  static const mutedBg = Color(0xFFECECF0);
  static const border = Color(0x1A000000);
  static const galerieGradientStart = Color(0xFFFB7185);
  static const galerieGradientEnd = Color(0xFFF59E0B);
}

ThemeData buildAromaTheme() {
  const outline = AromaColors.zinc200;
  const white = Color(0xFFFFFFFF);
  final scheme = ColorScheme.light(
    primary: AromaColors.primary,
    onPrimary: AromaColors.onPrimary,
    surface: white,
    onSurface: AromaColors.zinc900,
    onSurfaceVariant: AromaColors.zinc500,
    outline: outline,
    outlineVariant: AromaColors.zinc100,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: white,
    colorScheme: scheme.copyWith(
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: white,
      surfaceContainerLow: white,
      surfaceContainer: white,
      surfaceContainerHigh: white,
      surfaceContainerHighest: white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AromaColors.surface,
      foregroundColor: AromaColors.zinc900,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AromaColors.zinc900,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AromaColors.surface,
      elevation: 0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xCC_E4E4E7)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AromaColors.primary,
        foregroundColor: AromaColors.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AromaColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AromaColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const String _fontFamily = 'Cairo';

  static ThemeData light(Color primary) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceLight,
      background: AppColors.bgLight,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.textMedium),
        hintStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.textMuted),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        displaySmall:  TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),
        titleSmall:    TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
        bodyMedium:    TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
        bodySmall:     TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
        labelLarge:    TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        labelMedium:   TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),
        labelSmall:    TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerLight, thickness: 1, space: 0),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        labelStyle: TextStyle(fontFamily: _fontFamily, color: primary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: const TextStyle(fontFamily: _fontFamily),
      ),
    );
  }

  static ThemeData dark(Color primary) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceDark,
      background: AppColors.bgDark,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        titleTextStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          textStyle: const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.textMuted),
        hintStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.textMuted),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        titleLarge:    TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),
        bodyLarge:     TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
        bodyMedium:    TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
        labelLarge:    TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerDark, thickness: 1, space: 0),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textLight),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardDark,
        contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

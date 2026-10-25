import 'package:flutter/material.dart';

/// Universidad de Dagupan blue palette + game tile colors.
class AppColors {
  static const Color navy = Color(0xFF161675);
  static const Color navyLight = Color(0xFF3949AB);
  static const Color gold = Color(0xFFF5B700);
  static const Color background = Color(0xFFF4F5FB);

  // Letter tile states (Daily Word Guess)
  static const Color correct = Color(0xFF2E7D32);
  static const Color present = Color(0xFFF9A825);
  static const Color absent = Color(0xFF757575);
  static const Color empty = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.gold,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

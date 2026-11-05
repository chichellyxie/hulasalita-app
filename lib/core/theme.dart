import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Universidad de Dagupan navy + HulaSalita gold, plus game tile colors.
class AppColors {
  static const Color navy = Color(0xFF1B1F6B);
  static const Color navyDark = Color(0xFF0E1147);
  static const Color navyLight = Color(0xFF3949AB);
  static const Color navySoft = Color(0xFFE4E7F8); // chips, selected nav item
  static const Color gold = Color(0xFFF2B233);
  static const Color goldDark = Color(0xFFB07C10); // 3D shadow under gold buttons
  static const Color goldSoft = Color(0xFFFFF7E3); // "Did you know?" cards
  static const Color background = Color(0xFFF3F5FB);
  static const Color ink = Color(0xFF1B1F3B);
  static const Color muted = Color(0xFF5A6178);
  static const Color line = Color(0xFFE1E4F2);

  // Game colors
  static const Color bugtong = Color(0xFF5B2A9E);
  static const Color bugtongSoft = Color(0xFFEDE4FA);
  static const Color scramble = Color(0xFF0F6566);
  static const Color scrambleSoft = Color(0xFFDDF2F2);
  static const Color translate = Color(0xFF17734A);
  static const Color translateSoft = Color(0xFFDDF1E6);
  static const Color salawikain = Color(0xFF9A3412);
  static const Color salawikainSoft = Color(0xFFFBE3D6);
  static const Color sawikain = Color(0xFF9D174D);
  static const Color sawikainSoft = Color(0xFFFBE0EC);
  static const Color panitikan = Color(0xFF6B4600);
  static const Color panitikanSoft = Color(0xFFFCEBC4);
  static const Color context = Color(0xFF1E4FA8);
  static const Color contextSoft = Color(0xFFDDE8FB);

  // Letter tile states (Daily Word Guess) — also differ in lightness
  static const Color correct = Color(0xFF17734A);
  static const Color correctSoft = Color(0xFFDDF1E6);
  static const Color present = Color(0xFFF2B233);
  static const Color absent = Color(0xFF7A8099);
  static const Color empty = Color(0xFFFFFFFF);
  static const Color wrong = Color(0xFF8E2323);
  static const Color wrongSoft = Color(0xFFF8DEDE);
}

/// Rounded "Baloo 2" for titles, numbers and letter tiles.
TextStyle displayStyle({double size = 24, Color color = AppColors.navy, FontWeight weight = FontWeight.w800}) =>
    GoogleFonts.baloo2(fontSize: size, fontWeight: weight, color: color, height: 1.15);

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.gold,
      surface: Colors.white,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = GoogleFonts.nunitoTextTheme(base.textTheme).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text.copyWith(
        headlineSmall: displayStyle(size: 26, color: AppColors.ink),
        titleLarge: displayStyle(size: 22, color: AppColors.ink),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: displayStyle(size: 22, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.line)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD5D9EC), width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD5D9EC), width: 2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.navy, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.navy,
          textStyle: GoogleFonts.baloo2(fontSize: 19, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 2),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.navySoft,
        surfaceTintColor: Colors.transparent,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.navy : AppColors.muted),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w700,
            color: states.contains(WidgetState.selected) ? AppColors.navy : AppColors.muted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

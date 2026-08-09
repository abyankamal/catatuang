import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors (Stitch Design System)
  static const Color primary = Color(0xFF5D5CFF);       // Purplish Blue
  static const Color secondary = Color(0xFF0F172A);     // Deep Slate Navy
  static const Color tertiary = Color(0xFF38BDF8);      // Sky Blue
  static const Color neutral = Color(0xFFF8F9FA);       // Off White / Soft Grey

  // Semantic Financial Colors
  static const Color income = Color(0xFF10B981);       // Emerald Green
  static const Color incomeDark = Color(0xFF047857);
  static const Color incomeLight = Color(0xFFD1FAE5);

  static const Color expense = Color(0xFFEF4444);      // Crimson Red
  static const Color expenseDark = Color(0xFFB91C1C);
  static const Color expenseLight = Color(0xFFFEE2E2);

  static const Color transfer = Color(0xFF5D5CFF);     // Brand Primary
  static const Color transferDark = Color(0xFF1D4ED8);
  static const Color transferLight = Color(0xFFDBEAFE);

  // Negative balance card alert tint
  static const Color negativeAlertBg = Color(0xFFFEF2F2);
  static const Color negativeAlertBorder = Color(0xFFFCA5A5);

  // Background & Surfaces
  static const Color background = Color(0xFFF4F6F9);   // Soft neutral background
  static const Color cardSurface = Colors.white;
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      brightness: Brightness.light,
      surface: AppColors.cardSurface,
    );

    final textTheme = const TextTheme().copyWith(
      headlineLarge: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
      headlineMedium: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
      headlineSmall: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
      titleLarge: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.secondary),
      titleMedium: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondary),
      titleSmall: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondary),
      bodyLarge: const TextStyle(color: AppColors.secondary),
      bodyMedium: const TextStyle(color: AppColors.secondary),
      bodySmall: TextStyle(color: Colors.grey.shade600),
      labelLarge: const TextStyle(fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: Colors.grey.shade500),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme.copyWith(
        surface: AppColors.cardSurface,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.secondary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

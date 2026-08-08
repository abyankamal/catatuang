import 'package:flutter/material.dart';

class AppColors {
  // Semantic Financial Colors
  static const Color income = Color(0xFF10B981);       // Emerald Green
  static const Color incomeDark = Color(0xFF047857);
  static const Color incomeLight = Color(0xFFD1FAE5);

  static const Color expense = Color(0xFFEF4444);      // Crimson Red
  static const Color expenseDark = Color(0xFFB91C1C);
  static const Color expenseLight = Color(0xFFFEE2E2);

  static const Color transfer = Color(0xFF3B82F6);     // Royal Blue
  static const Color transferDark = Color(0xFF1D4ED8);
  static const Color transferLight = Color(0xFFDBEAFE);

  // Negative balance card alert tint
  static const Color negativeAlertBg = Color(0xFFFEF2F2);
  static const Color negativeAlertBorder = Color(0xFFFCA5A5);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);   // Very light grey
  static const Color cardSurface = Colors.white;
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F172A), // Slate 900 primary accent
      brightness: Brightness.light,
      surface: AppColors.cardSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme.copyWith(
        surface: AppColors.cardSurface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0.5,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFF0F172A).withAlpha(20),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

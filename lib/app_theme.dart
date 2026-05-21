import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF1E3A5F);
  static const Color navyDark = Color(0xFF0D2137);
  static const Color blue = Color(0xFF1565C0);
  static const Color blueLight = Color(0xFF42A5F5);
  static const Color orange = Color(0xFFFF6D00);
  static const Color green = Color(0xFF27AE60);
  static const Color red = Color(0xFFE53935);
  static const Color bg = Color(0xFFF2F6FC);
  static const Color textSecondary = Color(0xFF78909C);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.blue, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  static BoxDecoration gradientHeader({bool dark = false}) => BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [AppColors.navyDark, AppColors.navy]
              : [AppColors.blue, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
}

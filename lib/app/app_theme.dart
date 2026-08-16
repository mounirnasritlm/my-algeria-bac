import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF10B981);
  static const xp = Color(0xFFF59E0B);
  static const streak = Color(0xFFF97316);
  static const mastery = Color(0xFF8B5CF6);
  static const bac = Color(0xFF0F766E);

  static const backgroundLight = Color(0xFFF7F9FC);
  static const surfaceLight = Colors.white;
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    return _build(
      brightness: Brightness.light,
      background: AppColors.backgroundLight,
      surface: AppColors.surfaceLight,
    );
  }

  static ThemeData get dark {
    return _build(
      brightness: Brightness.dark,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,

      colorScheme: colorScheme,

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),

      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
    );
  }
}

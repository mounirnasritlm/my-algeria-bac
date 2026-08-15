import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const primary = Color(0xFF2563EB);
    const secondary = Color(0xFF10B981);
    const background = Color(0xFFF7F9FC);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        secondary: secondary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: 0.12),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

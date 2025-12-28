import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Color palette
  static const Color _primaryLight = Color(0xFF2D7DD2);
  static const Color _primaryDark = Color(0xFF5DA9E9);
  static const Color _surfaceLight = Color(0xFFFAFAFA);
  static const Color _surfaceDark = Color(0xFF121212);
  static const Color _backgroundLight = Color(0xFFFFFFFF);
  static const Color _backgroundDark = Color(0xFF1E1E1E);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryLight,
        brightness: Brightness.light,
        surface: _surfaceLight,
      ),
      scaffoldBackgroundColor: _backgroundLight,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryDark,
        brightness: Brightness.dark,
        surface: _surfaceDark,
      ),
      scaffoldBackgroundColor: _backgroundDark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}


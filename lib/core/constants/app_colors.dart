import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light palette
  static const lightBackground = Color(0xFFF7F4EF);
  static const lightSurface = Color(0xFFEFEBE4);
  static const lightPrimary = Color(0xFF4A7C6F);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFFC8956C);
  static const lightOnBackground = Color(0xFF2A2A2A);
  static const lightOnSurface = Color(0xFF3A3A3A);
  static const lightSubtle = Color(0xFF888580);

  // Dark palette
  static const darkBackground = Color(0xFF1A1F2E);
  static const darkSurface = Color(0xFF252B3B);
  static const darkPrimary = Color(0xFF7BAAA0);
  static const darkOnPrimary = Color(0xFF1A1F2E);
  static const darkSecondary = Color(0xFFD4A882);
  static const darkOnBackground = Color(0xFFE8E4DC);
  static const darkOnSurface = Color(0xFFD0CCC4);
  static const darkSubtle = Color(0xFF7A7D88);

  static ColorScheme lightScheme() => ColorScheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        secondary: lightSecondary,
        onSecondary: lightOnPrimary,
        surface: lightSurface,
        onSurface: lightOnSurface,
        error: const Color(0xFFB00020),
        onError: lightOnPrimary,
        surfaceContainerHighest: const Color(0xFFE0DDD6),
        outline: const Color(0xFFBBB8B2),
      );

  static ColorScheme darkScheme() => ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        secondary: darkSecondary,
        onSecondary: darkBackground,
        surface: darkSurface,
        onSurface: darkOnSurface,
        error: const Color(0xFFCF6679),
        onError: darkBackground,
        surfaceContainerHighest: const Color(0xFF2F3548),
        outline: const Color(0xFF4A4F60),
      );
}

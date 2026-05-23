import 'package:flutter/material.dart';

class AppTheme {
  // Colores
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131A);
  static const Color surfaceLight = Color(0xFF1E1E2A);
  static const Color accent = Color(0xFFE8A838);
  static const Color accentDim = Color(0x44E8A838);
  static const Color textPrimary = Color(0xFFF0EDE8);
  static const Color textSecondary = Color(0xFF7A7A8A);
  static const Color divider = Color(0xFF2A2A38);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          surface: surface,
          onSurface: textPrimary,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: accent,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: accent,
          inactiveTrackColor: surfaceLight,
          thumbColor: accent,
          overlayColor: accentDim,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
      );
}

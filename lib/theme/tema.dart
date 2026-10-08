import 'package:flutter/material.dart';

class TemaFactucell {
  static ThemeData get claro {
    return ThemeData(
      primaryColor: const Color(0xFFFF6600),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFFF6600),
        secondary: const Color(0xFFFFCC00),
        surface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFF6600),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6600),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  static ThemeData get oscuro {
    return ThemeData(
      primaryColor: const Color(0xFFFF6600),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFFF6600),
        secondary: const Color(0xFFFFCC00),
        surface: const Color(0xFF1A1A1A),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF222222),
        foregroundColor: const Color(0xFFFF6600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6600),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

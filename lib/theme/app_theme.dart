// ==================================================
// FACTUCELL — Tema y Paleta de Colores
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Estilo: Fuego, Chispas y Pirotecnia 🎇
// ==================================================

import 'package:flutter/material.dart';

class TemaFactucell {
  // 🔥 COLORES PRINCIPALES — Estilo Pirotecnia
  static const Color rojoFuego = Color(0xFFE63946);
  static const Color naranjaChispa = Color(0xFFFF9F1C);
  static const Color doradoBrillo = Color(0xFFFFD60A);
  static const Color negroFondo = Color(0xFF0F0F1E);
  static const Color azulOscuro = Color(0xFF1A1A2E);
  static const Color grisTarjeta = Color(0xFF232342);
  static const Color blancoTexto = Color(0xFFFFFFFF);
  static const Color grisSuave = Color(0xFFB8B8D1);
  static const Color verdeExito = Color(0xFF06D6A0);

  // ☀️ TEMA CLARO
  static ThemeData get claro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: rojoFuego,
      scaffoldBackgroundColor: const Color(0xFFFFF8F0),
      colorScheme: ColorScheme.light(
        primary: rojoFuego,
        secondary: naranjaChispa,
        tertiary: doradoBrillo,
        onPrimary: blancoTexto,
        onSecondary: negroFondo,
        surface: Colors.white,
        onSurface: negroFondo,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: rojoFuego,
        foregroundColor: blancoTexto,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shadowColor: naranjaChispa.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: rojoFuego,
          foregroundColor: blancoTexto,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: negroFondo),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF333333)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF555555)),
      ),
    );
  }

  // 🌑 TEMA OSCURO — Estilo Noche de Fuegos
  static ThemeData get oscuro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: rojoFuego,
      scaffoldBackgroundColor: negroFondo,
      colorScheme: ColorScheme.dark(
        primary: rojoFuego,
        secondary: naranjaChispa,
        tertiary: doradoBrillo,
        onPrimary: blancoTexto,
        onSecondary: negroFondo,
        surface: azulOscuro,
        onSurface: blancoTexto,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: azulOscuro,
        foregroundColor: doradoBrillo,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardTheme(
        color: grisTarjeta,
        elevation: 6,
        shadowColor: rojoFuego.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: rojoFuego,
          foregroundColor: blancoTexto,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: blancoTexto),
        bodyLarge: TextStyle(fontSize: 16, color: grisSuave),
        bodyMedium: TextStyle(fontSize: 14, color: grisSuave),
      ),
    );
  }
}

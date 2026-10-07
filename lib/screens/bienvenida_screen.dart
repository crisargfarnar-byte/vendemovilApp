// ==================================================
// FACTUCELL — Pantalla de Bienvenida
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Rubro: Artículos y Juegos Pirotécnicos 🎆
// ==================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'configuracion_inicial_screen.dart';

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔥 LOGO / ÍCONO
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: TemaFactucell.rojoFuego.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fireworks_rounded,
                    size: 80,
                    color: TemaFactucell.rojoFuego,
                  ),
                ),
                const SizedBox(height: 32),

                // ✨ NOMBRE DE LA APP
                Text(
                  'FACTUCELL',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: TemaFactucell.rojoFuego,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),

                // 📍 UBICACIÓN Y GIRO
                const Text(
                  'Sistema de Ventas y Facturación\nArtículos y Juegos Pirotécnicos\nGuayaquil — Ecuador 🇪🇨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: TemaFactucell.grisSuave,
                  ),
                ),
                const SizedBox(height: 48),

                // ▶️ BOTÓN DE INICIO
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PantallaConfiguracionInicial(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Comenzar →',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

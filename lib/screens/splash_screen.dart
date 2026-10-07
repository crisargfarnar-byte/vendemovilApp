// ==================================================
// FACTUCELL — Pantalla de Carga / Splash
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Estilo: Encendido Pirotécnico 🎇
// ==================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'bienvenida_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controlador;
  late Animation<double> _animacionFade;
  late Animation<double> _animacionEscala;

  @override
  void initState() {
    super.initState();

    // 🎬 Control de animación — estilo chispa encendiéndose
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _animacionFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.easeIn),
    );

    _animacionEscala = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.elasticOut),
    );

    _controlador.forward();

    // ⏳ Avanzar a Bienvenida tras carga
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaBienvenida()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaFactucell.negroFondo,
      body: AnimatedBuilder(
        animation: _controlador,
        builder: (context, child) {
          return Opacity(
            opacity: _animacionFade.value,
            child: Transform.scale(
              scale: _animacionEscala.value,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔥 Ícono principal — fuego
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: TemaFactucell.rojoFuego.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: TemaFactucell.naranjaChispa.withOpacity(0.2),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fireworks_rounded,
                        size: 100,
                        color: TemaFactucell.doradoBrillo,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ✨ NOMBRE
                    Text(
                      'FACTUCELL',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: TemaFactucell.doradoBrillo.withOpacity(0.6),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 📍 Subtítulo
                    const Text(
                      'Ventas • Facturación • Pirotecnia\nGuayaquil, Ecuador 🇪🇨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: TemaFactucell.grisSuave,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ⏳ Cargando...
                    const CircularProgressIndicator(
                      color: TemaFactucell.naranjaChispa,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

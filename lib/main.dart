// ==================================================
// FACTUCELL — Sistema de Ventas y Facturación
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Rubro: Artículos y Juegos Pirotécnicos 🎆
// ==================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/tema.dart';
import 'screens/inicio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FactucellApp());
}

class FactucellApp extends StatelessWidget {
  const FactucellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Factucell',
      debugShowCheckedModeBanner: false,
      theme: TemaFactucell.claro,
      darkTheme: TemaFactucell.oscuro,
      themeMode: ThemeMode.system,
      home: const PantallaInicio(),
    );
  }
}

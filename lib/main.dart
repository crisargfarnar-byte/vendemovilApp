import 'package:flutter/material.dart';
import 'screens/inicio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Factucell - Pirotecnia Ecuador',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF6600)
  useMaterial3: true,
),
darkTheme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFFFF6600),
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
),

      
      home: const PantallaInicio(),
    );
  }
}

import 'package:flutter/material.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factucell - Ecuador 🇪🇨'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(Icons.fireworks, size: 80, color: Color(0xFFFF6600)),


              const SizedBox(height: 24),
              const Text(
                '¡Bienvenido a Factucell!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu sistema de facturación para pirotecnia\nEcuador 🇪🇨',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Comenzar', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

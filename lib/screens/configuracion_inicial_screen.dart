// ==================================================
// FACTUCELL — Configuración Inicial del Negocio
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Rubro: Artículos y Juegos Pirotécnicos 🎆
// ==================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/onboarding_service.dart';
import 'scanner_pos_screen.dart';

class ConfiguracionInicialScreen extends StatefulWidget {
  const ConfiguracionInicialScreen({super.key});

  @override
  State<ConfiguracionInicialScreen> createState() => _ConfiguracionInicialScreenState();
}

class _ConfiguracionInicialScreenState extends State<ConfiguracionInicialScreen> {
  final _formKey = GlobalKey<FormState>();

  // 📋 CAMPOS PRE-CONFIGURADOS PARA TU NEGOCIO
  final _nombreCtrl = TextEditingController(text: 'FACTUCELL — Pirotecnia');
  final _rubroCtrl = TextEditingController(text: 'Artículos y Juegos Pirotécnicos');
  final _monedaCtrl = TextEditingController(text: 'USD — Dólar Estadounidense');
  final _ciudadCtrl = TextEditingController(text: 'Guayaquil, Guayas');
  final _paisCtrl = TextEditingController(text: 'Ecuador');
  final _telefonoCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController(text: '¡Gracias por su compra! 🎆');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rubroCtrl.dispose();
    _monedaCtrl.dispose();
    _ciudadCtrl.dispose();
    _paisCtrl.dispose();
    _telefonoCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarYContinuar() async {
    if (!_formKey.currentState!.validate()) return;

    await OnboardingService.completarConfiguracion({
      'nombre_negocio': _nombreCtrl.text.trim(),
      'rubro': _rubroCtrl.text.trim(),
      'moneda': 'USD',
      'simbolo_moneda': '\$',
      'decimales': 2,
      'ciudad': _ciudadCtrl.text.trim(),
      'pais': _paisCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'mensaje_recibo': _mensajeCtrl.text.trim(),
      'fecha_configuracion': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ScannerPOSScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Negocio'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 🔥 TÍTULO
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.local_fireworks_rounded, size: 48, color: TemaFactucell.rojoFuego),
                    SizedBox(height: 12),
                    Text(
                      'Datos de tu Negocio',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Todo listo para vender y facturar 🎆',
                      style: TextStyle(color: TemaFactucell.grisSuave),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 🏪 NOMBRE DEL NEGOCIO
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Negocio',
                  prefixIcon: Icon(Icons.storefront),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),

              // 🎇 GIRO / RUBRO
              TextFormField(
                controller: _rubroCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rubro / Actividad',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el rubro' : null,
              ),
              const SizedBox(height: 16),

              // 💰 MONEDA
              TextFormField(
                controller: _monedaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Moneda',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                enabled: false,
                style: const TextStyle(color: TemaFactucell.naranjaChispa, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // 📍 UBICACIÓN
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _ciudadCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _paisCtrl,
                      decoration: const InputDecoration(
                        labelText: 'País',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 📞 TELÉFONO
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono / WhatsApp',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),

              // ✉️ MENSAJE EN RECIBO
              TextFormField(
                controller: _mensajeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mensaje en Recibos',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 32),

              // ✅ BOTÓN GUARDAR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarYContinuar,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Guardar y Comenzar →', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

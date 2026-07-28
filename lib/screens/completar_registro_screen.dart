import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'scanner_pos_screen.dart';

class CompletarRegistroScreen extends StatefulWidget {
  final String nombrePrellenado;
  const CompletarRegistroScreen({super.key, required this.nombrePrellenado});

  @override
  State<CompletarRegistroScreen> createState() => _CompletarRegistroScreenState();
}

class _CompletarRegistroScreenState extends State<CompletarRegistroScreen> {
  late final TextEditingController _nombreCtrl;
  final _negocioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.nombrePrellenado);
  }

  Future<void> _completar() async {
    final nombre = _nombreCtrl.text.trim();
    final negocio = _negocioCtrl.text.trim();

    if (nombre.isEmpty || negocio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('negocio_nombre', negocio);
    await prefs.setBool('is_logged_in', true);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ScannerPosScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite,
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        backgroundColor: AppTheme.bgWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Falta un paso más', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Completa esta información para configurar tu tienda.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 32),
            TextField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Tu Nombre',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _negocioCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre de tu Negocio',
                prefixIcon: const Icon(Icons.store_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _completar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Comenzar a Vender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

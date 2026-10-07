// ==================================================
// FACTUCELL — Ajustes / Configuración
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Rubro: Artículos y Juegos Pirotécnicos 🎆
// ==================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/printer_service.dart';
import '../services/database_service.dart';
import '../utils/metodos_pago_config.dart';
import '../widgets/soporte_dialog.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  Map<String, dynamic> _datosNegocio = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _datosNegocio = {
        'nombre': prefs.getString('nombre_negocio') ?? 'FACTUCELL — Pirotecnia',
        'rubro': prefs.getString('rubro') ?? 'Artículos y Juegos Pirotécnicos',
        'moneda': prefs.getString('moneda') ?? 'USD',
        'simbolo': prefs.getString('simbolo_moneda') ?? '\$',
        'ciudad': prefs.getString('ciudad') ?? 'Guayaquil, Guayas',
        'pais': prefs.getString('pais') ?? 'Ecuador',
        'telefono': prefs.getString('telefono') ?? '',
        'mensaje_recibo': prefs.getString('mensaje_recibo') ?? '¡Gracias por su compra! 🎆',
      };
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: TemaFactucell.rojoFuego,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: TemaFactucell.naranjaChispa))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 🏪 DATOS DEL NEGOCIO
                _seccionTitulo('Datos del Negocio', Icons.storefront),
                _tarjetaInfo([
                  _datoFila('Nombre', _datosNegocio['nombre']),
                  _datoFila('Rubro', _datosNegocio['rubro']),
                  _datoFila('Moneda', '${_datosNegocio['simbolo']} ${_datosNegocio['moneda']}'),
                  _datoFila('Ubicación', '${_datosNegocio['ciudad']} — ${_datosNegocio['pais']}'),
                  if (_datosNegocio['telefono'].isNotEmpty)
                    _datoFila('Teléfono', _datosNegocio['telefono']),
                  _datoFila('Mensaje Recibo', _datosNegocio['mensaje_recibo']),
                ]),
                const SizedBox(height: 24),

                // 💰 MÉTODOS DE PAGO
                _seccionTitulo('Métodos de Pago', Icons.payment),
                _botonOpcion(
                  icon: Icons.payments,
                  titulo: 'Configurar Medios de Pago',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MetodosPagoConfig())),
                ),
                const SizedBox(height: 24),

                // 🖨️ IMPRESIÓN
                _seccionTitulo('Impresión', Icons.print),
                _botonOpcion(
                  icon: Icons.bluetooth,
                  titulo: 'Conectar Impresora Bluetooth',
                  onTap: () => PrinterService.conectarImpresora(context),
                ),
                const SizedBox(height: 24),

                // 📦 RESPALDO
                _seccionTitulo('Base de Datos', Icons.storage),
                _botonOpcion(
                  icon: Icons.backup,
                  titulo: 'Exportar Datos',
                  onTap: () => DatabaseService.exportarBaseDatos(context),
                ),
                _botonOpcion(
                  icon: Icons.restore,
                  titulo: 'Restaurar / Importar',
                  onTap: () => DatabaseService.importarBaseDatos(context),
                ),
                const SizedBox(height: 24),

                // 🆘 SOPORTE
                _seccionTitulo('Ayuda', Icons.help_outline),
                _botonOpcion(
                  icon: Icons.support_agent,
                  titulo: 'Contactar Soporte',
                  onTap: () => showDialog(context: context, builder: (_) => const SoporteDialog()),
                ),
                const SizedBox(height: 32),

                // ℹ️ VERSIÓN
                const Center(
                  child: Text(
                    'FACTUCELL v1.0 — Pirotecnia\nGuayaquil, Ecuador 🇪🇨',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TemaFactucell.grisSuave, fontSize: 13),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _seccionTitulo(String texto, IconData icono) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Row(children: [
          Icon(icono, color: TemaFactucell.naranjaChispa, size: 20),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _tarjetaInfo(List<Widget> hijos) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: hijos)),
      );

  Widget _datoFila(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text('$etiqueta:', style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(valor)),
          ],
        ),
      );

  Widget _botonOpcion({required IconData icon, required String titulo, required VoidCallback onTap}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(icon, color: TemaFactucell.rojoFuego),
          title: Text(titulo),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
        ),
      );
}

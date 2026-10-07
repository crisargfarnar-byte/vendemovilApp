// ==================================================
// FACTUCELL — Punto de Venta con Escáner
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Rubro: Artículos y Juegos Pirotécnicos 🎆
// ==================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../providers/carrito_provider.dart';
import '../utils/safe_area_padding.dart';
import '../utils/currency_formatter.dart';
import '../utils/sound_player.dart';
import '../widgets/safe_bottom_bar.dart';
import '../widgets/payment_dialog.dart';
import '../models/producto.dart';
import '../models/venta.dart';

class ScannerPOSScreen extends StatefulWidget {
  const ScannerPOSScreen({super.key});

  @override
  State<ScannerPOSScreen> createState() => _ScannerPOSScreenState();
}

class _ScannerPOSScreenState extends State<ScannerPOSScreen> {
  final MobileScannerController _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  
  bool _escaneando = true;
  bool _procesando = false;
  String? _nombreNegocio;
  String? _mensajePie;

  @override
  void initState() {
    super.initState();
    _cargarDatosNegocio();
  }

  Future<void> _cargarDatosNegocio() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreNegocio = prefs.getString('nombre_negocio') ?? 'FACTUCELL — Pirotecnia 🎆';
      _mensajePie = prefs.getString('mensaje_pie') ?? '¡Gracias por su compra! Vuelva pronto 🎇';
    });
  }

  Future<void> _alAgregarPorCodigo(String codigo, CarritoProvider carrito) async {
    if (_procesando) return;
    _procesando = true;

    try {
      final producto = await DatabaseService.buscarProductoPorCodigo(codigo);
      
      if (producto == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Producto no encontrado'), backgroundColor: Colors.orange)
          );
        }
        return;
      }

      if (producto.stock <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Sin stock disponible'), backgroundColor: Colors.red)
          );
        }
        return;
      }

      await SoundPlayer.beep();
      carrito.agregarItem(producto);

    } catch (e) {
      debugPrint('Error al agregar: $e');
    } finally {
      _procesando = false;
    }
  }

  Future<void> _finalizarVenta(CarritoProvider carrito) async {
    if (carrito.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🛒 El carrito está vacío'))
      );
      return;
    }

    final pago = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PaymentDialog(
        total: carrito.total,
        nombreNegocio: _nombreNegocio,
        mensajePie: _mensajePie,
      ),
    );

    if (pago == null) return;

    setState(() => _procesando = true);

    try {
      final venta = Venta(
        fecha: DateTime.now().toIso8601String(),
        items: carrito.items.map((i) => {
          'id_producto': i.producto.id,
          'nombre': i.producto.nombre,
          'cantidad': i.cantidad,
          'precio_unitario': i.producto.precioVenta,
          'subtotal': i.subtotal,
        }).toList(),
        total: carrito.total,
        metodoPago: pago['metodo'],
        recibido: pago['recibido'],
        cambio: pago['cambio'] ?? 0,
      );

      await DatabaseService.registrarVenta(venta);
      
      for (var item in carrito.items) {
        await DatabaseService.actualizarStock(
          item.producto.id!,
          item.producto.stock - item.cantidad
        );
      }

      await SoundPlayer.success();
      carrito.limpiar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Venta registrada con éxito 🎉'), backgroundColor: Colors.green)
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carrito = Provider.of<CarritoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_nombreNegocio ?? 'Punto de Venta 🎆'),
        backgroundColor: TemaFactucell.rojoFuego,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_escaneando ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _escaneando = !_escaneando),
            tooltip: _escaneando ? 'Pausar escáner' : 'Activar escáner',
          ),
        ],
      ),
      body: SafeAreaPadding(
        child: Column(
          children: [
            // 📷 ESCÁNER
            if (_escaneando)
              SizedBox(
                height: 180,
                child: MobileScanner(
                  controller: _scannerCtrl,
                  onDetect: (capture) {
                    final codes = capture.barcodes;
                    for (final code in codes) {
                      if (code.rawValue != null) {
                        _alAgregarPorCodigo(code.rawValue!, carrito);
                      }
                    }
                  },
                ),
              ),

            // 🔍 BUSCAR MANUALMENTE
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Escribir código o nombre...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                onSubmitted: (cod) => _alAgregarPorCodigo(cod.trim(), carrito),
              ),
            ),

            // 🛒 LISTA DEL CARRITO
            Expanded(
              child: carrito.items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Escanea o busca productos', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: carrito.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = carrito.items[i];
                        return ListTile(
                          title: Text(item.producto.nombre),
                          subtitle: Text('${item.producto.categoria ?? 'General'}'),
                          leading: CircleAvatar(
                            backgroundColor: TemaFactucell.naranjaChispa.withOpacity(0.15),
                            child: Text('×${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold, color: TemaFactucell.naranjaChispa)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(CurrencyFormatear.monto(item.subtotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => carrito.quitarItem(item.producto.id!),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // 💰 TOTAL Y BOTÓN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(CurrencyFormatear.monto(carrito.total),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: TemaFactucell.rojoFuego)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _procesando ? null : () => _finalizarVenta(carrito),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaFactucell.naranjaChispa,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _procesando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.payment, color: Colors.white),
                      label: Text(
                        _procesando ? 'Procesando...' : 'Finalizar Venta',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeBottomBar(indiceActivo: 0),
    );
  }
}

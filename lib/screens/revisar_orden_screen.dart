import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/carrito_provider.dart';
import '../services/printer_service.dart';
import '../utils/currency_formatter.dart';
import '../models/venta.dart';

class RevisarOrdenScreen extends StatefulWidget {
  const RevisarOrdenScreen({super.key});
  @override
  State<RevisarOrdenScreen> createState() => _RevisarOrdenScreenState();
}

class _RevisarOrdenScreenState extends State<RevisarOrdenScreen> {
  String _metodoPago = 'efectivo';
  final _montoCtrl = TextEditingController();
  bool _procesando = false;
  String? _yapeQrPath;
  String _monedaSimbolo = 'S/';

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  Future<void> _cargarAjustes() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _yapeQrPath = prefs.getString('yape_qr_path');
        _monedaSimbolo = prefs.getString('moneda_simbolo') ?? 'S/';
      });
    }
  }

  String _formatMoney(double amount) {
    return CurrencyFormatter.format(amount, _monedaSimbolo);
  }

  double _getVuelto(double total) {
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    return (monto - total).clamp(0, double.infinity);
  }

  Future<void> _procesar(CarritoProvider carrito) async {
    if (_metodoPago == 'efectivo') {
      final monto = double.tryParse(_montoCtrl.text) ?? 0;
      if (monto < carrito.total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monto insuficiente'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }
    setState(() => _procesando = true);
    try {
      final venta = await carrito.finalizarVenta(
        metodoPago: _metodoPago,
        montoPagado: _metodoPago == 'efectivo'
            ? double.tryParse(_montoCtrl.text)
            : null,
      );

      // Auto imprimir
      try {
        await PrinterService.instance.imprimirTicket(venta);
        HapticFeedback.heavyImpact();
        try {
          AudioPlayer().play(AssetSource('sounds/caja.mp3'));
        } catch (_) {}
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta guardada pero no se pudo imprimir: $e'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
      }

      if (mounted) _mostrarExito(venta);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _procesando = false);
  }

  void _mostrarExito(Venta venta) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 56,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Venta Exitosa!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _formatMoney(venta.total),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            if (venta.vuelto != null && venta.vuelto! > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.reply, color: AppTheme.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Vuelto: ${_formatMoney(venta.vuelto!)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await PrinterService.instance.imprimirTicket(venta);
                      HapticFeedback.heavyImpact();
                      try {
                        AudioPlayer().play(AssetSource('sounds/caja.mp3'));
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.print_rounded, size: 20),
                    label: const Text('Imprimir'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx); // dialog
                      Navigator.pop(context); // back to scanner
                    },
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Listo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarritoProvider>(
      builder: (context, carrito, _) {
        if (carrito.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return const Scaffold();
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Revisar Orden'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumen de items
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${carrito.totalItems} artículos',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...carrito.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.productoNombre,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              'x${item.cantidad}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _formatMoney(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatMoney(carrito.total),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Método de pago
              const Text(
                'Método de Pago',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetodo(
                    'efectivo',
                    Icons.money_rounded,
                    'Efectivo',
                    AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  _buildMetodo(
                    'yape',
                    Icons.phone_android_rounded,
                    'Yape',
                    const Color(0xFF6C2DC7),
                  ),
                  const SizedBox(width: 8),
                  _buildMetodo(
                    'plin',
                    Icons.phone_iphone_rounded,
                    'Plin',
                    const Color(0xFF00BFA5),
                  ),
                  const SizedBox(width: 8),
                  _buildMetodo(
                    'tarjeta',
                    Icons.credit_card_rounded,
                    'Tarjeta',
                    AppTheme.info,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Yape QR Code
              if (_metodoPago == 'yape' && _yapeQrPath != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Escanea para pagar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6C2DC7),
                        width: 2,
                      ),
                    ),
                    child: Image.file(
                      File(_yapeQrPath!),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Monto recibido (solo efectivo)
              if (_metodoPago == 'efectivo') ...[
                const Text(
                  'Monto Recibido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: 'S/ ',
                    prefixStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    filled: true,
                    fillColor: AppTheme.bgWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Montos rápidos
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [5, 10, 20, 50, 100, 200]
                      .map(
                        (m) => ActionChip(
                          label: Text(
                            'S/$m',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          backgroundColor: AppTheme.bgWhite,
                          side: const BorderSide(color: AppTheme.border),
                          onPressed: () {
                            _montoCtrl.text = '$m.00';
                            setState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                if (_getVuelto(carrito.total) > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.reply, color: AppTheme.warning),
                            SizedBox(width: 8),
                            Text(
                              'Vuelto:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatMoney(_getVuelto(carrito.total)),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),
              // Botón confirmar
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _procesando ? null : () => _procesar(carrito),
                  icon: _procesando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 22),
                  label: Text(
                    _procesando ? 'Procesando...' : 'Confirmar Venta',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetodo(String value, IconData icon, String label, Color color) {
    final selected = _metodoPago == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _metodoPago = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : AppTheme.bgWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? color : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }
}

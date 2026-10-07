// ==================================================
// FACTUCELL — Historial de Ventas
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Rubro: Artículos y Juegos Pirotécnicos 🎆
// ==================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/printer_service.dart';
import '../models/venta.dart';
import '../utils/safe_area_padding.dart';
import '../utils/currency_formatter.dart';
import '../utils/whatsapp_share.dart';
import '../widgets/safe_bottom_bar.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Venta> _ventas = [];
  List<Venta> _filtradas = [];
  bool _cargando = true;
  String _filtro = 'hoy';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  final TextEditingController _buscarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => _cargando = true);
    try {
      final lista = await DatabaseService.obtenerTodasLasVentas();
      setState(() {
        _ventas = lista;
        _aplicarFiltro();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _aplicarFiltro() {
    final ahora = DateTime.now();
    DateTime inicio, fin;

    switch (_filtro) {
      case 'hoy':
        inicio = DateTime(ahora.year, ahora.month, ahora.day);
        fin = inicio.add(const Duration(days: 1));
        break;
      case 'semana':
        inicio = ahora.subtract(Duration(days: ahora.weekday - 1));
        inicio = DateTime(inicio.year, inicio.month, inicio.day);
        fin = inicio.add(const Duration(days: 7));
        break;
      case 'mes':
        inicio = DateTime(ahora.year, ahora.month, 1);
        fin = DateTime(ahora.year, ahora.month + 1, 1);
        break;
      case 'personalizado':
        if (_fechaInicio != null && _fechaFin != null) {
          inicio = _fechaInicio!;
          fin = _fechaFin!.add(const Duration(days: 1));
        } else {
          _filtradas = _ventas;
          return;
        }
        break;
      default:
        _filtradas = _ventas;
        return;
    }

    String busqueda = _buscarCtrl.text.trim().toLowerCase();
    _filtradas = _ventas.where((v) {
      final fechaVenta = DateTime.parse(v.fecha);
      bool enRango = fechaVenta.isAfter(inicio.subtract(const Duration(seconds: 1))) &&
                     fechaVenta.isBefore(fin);
      if (!enRango) return false;
      if (busqueda.isEmpty) return true;
      return v.items.any((item) =>
        item['nombre'].toString().toLowerCase().contains(busqueda)
      ) || busqueda.contains(v.total.toString());
    }).toList();
  }

  double get _totalPeriodo => _filtradas.fold(0, (sum, v) => sum + v.total);

  Future<void> _exportarExcel() async {
    if (_filtradas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar'))
      );
      return;
    }

    final excel = Excel.createExcel();
    final hoja = excel['Ventas'];
    
    hoja.appendRow(['Fecha', 'Productos', 'Total', 'Método de Pago']);
    for (var v in _filtradas) {
      hoja.appendRow([
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(v.fecha)),
        v.items.map((i) => '${i['cantidad']}x ${i['nombre']}').join(' | '),
        v.total,
        v.metodoPago,
      ]);
    }

    final directorio = await getTemporaryDirectory();
    final ruta = '${directorio.path}/ventas_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    await excel.save(fileName: ruta);
    await Share.shareXFiles([XFile(ruta)], text: 'Reporte de Ventas — FACTUCELL 🎆');
  }

  void _verDetalle(Venta venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Detalle de Venta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(DateFormat('EEEE, dd/MM/yyyy — HH:mm').format(DateTime.parse(venta.fecha))),
            const Divider(height: 24),
            ...venta.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item['cantidad']}x ${item['nombre']}'),
                  Text(CurrencyFormatear.monto(item['subtotal']),
                       style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(CurrencyFormatear.monto(venta.total),
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TemaFactucell.rojoFuego)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Pago: ${venta.metodoPago}'),
            if (venta.metodoPago == 'Efectivo' && venta.cambio != null)
              Text('Recibido: \$${venta.recibido} | Cambio: \$${venta.cambio}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: TemaFactucell.naranjaChispa),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text('Imprimir', style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas 📋'),
        backgroundColor: TemaFactucell.rojoFuego,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportarExcel,
            tooltip: 'Exportar Excel',
          ),
        ],
      ),
      body: SafeAreaPadding(
        child: Column(
          children: [
            // 🔍 FILTROS Y BÚSQUEDA
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _buscarCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por producto o monto...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onChanged: (_) => setState(() => _aplicarFiltro()),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _botonFiltro('Hoy', 'hoy'),
                        const SizedBox(width: 8),
                        _botonFiltro('Semana', 'semana'),
                        const SizedBox(width: 8),
                        _botonFiltro('Mes', 'mes'),
                        const SizedBox(width: 8),
                        _botonFiltro('Personalizado', 'personalizado'),
                      ],
                    ),
                  ),
                  if (_filtro == 'personalizado') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_fechaInicio != null
                                ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                                : 'Desde'),
                            onPressed: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) setState(() {
                                _fechaInicio = fecha;
                                _aplicarFiltro();
                              });
                            },
                          ),
                        ),
                        const Text(' — '),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_fechaFin != null
                                ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                                : 'Hasta'),
                            onPressed: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now(),
                              );
                              if (fecha != null) setState(() {
                                _fechaFin = fecha;
                                _aplicarFiltro();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 💰 TOTAL DEL PERÍODO
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaFactucell.naranjaChispa.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total del período:', style: TextStyle(fontSize: 16)),
                  Text(CurrencyFormatear.monto(_totalPeriodo),
                       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaFactucell.rojoFuego)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 📋 LISTA DE VENTAS
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: TemaFactucell.naranjaChispa))
                  : _filtradas.isEmpty
                      ? const Center(child: Text('No hay ventas en este período', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtradas.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final venta = _filtradas[i];
                            final fecha = DateTime.parse(venta.fecha);
                            return ListTile(
                              onTap: () => _verDetalle(venta),
                              leading: CircleAvatar(
                                backgroundColor: TemaFactucell.naranjaChispa.withOpacity(0.2),
                                child: Text('${venta.items.length}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: TemaFactucell.naranjaChispa)),
                              ),
                              title: Text(DateFormat('dd/MM/yyyy HH:mm').format(fecha)),
                              subtitle: Text('${venta.items.length} producto(s) • ${venta.metodoPago}'),
                              trailing: Text(CurrencyFormatear.monto(venta.total),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeBottomBar(indiceActivo: 1),
    );
  }

  Widget _botonFiltro(String etiqueta, String valor) {
    final seleccionado = _filtro == valor;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: seleccionado ? TemaFactucell.naranjaChispa : Colors.grey[200],
        foregroundColor: seleccionado ? Colors.white : Colors.black87,
      ),
      onPressed: () => setState(() {
        _filtro = valor;
        _aplicarFiltro();
      }),
      child: Text(etiqueta),
    );
  }
}

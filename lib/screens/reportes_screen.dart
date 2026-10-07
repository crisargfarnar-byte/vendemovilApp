// ==================================================
// FACTUCELL — Reportes y Estadísticas
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
import '../models/venta.dart';
import '../models/producto.dart';
import '../utils/safe_area_padding.dart';
import '../utils/currency_formatter.dart';
import '../widgets/safe_bottom_bar.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  bool _cargando = true;
  List<Venta> _ventas = [];
  List<Producto> _productos = [];
  Map<String, double> _ventasPorCategoria = {};
  Map<String, double> _topProductos = {};
  double _totalGeneral = 0;
  double _costoTotal = 0;
  double _gananciaNeta = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      _ventas = await DatabaseService.obtenerTodasLasVentas();
      _productos = await DatabaseService.obtenerTodosLosProductos();
      _procesarEstadisticas();
      setState(() => _cargando = false);
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _procesarEstadisticas() {
    _totalGeneral = 0;
    _costoTotal = 0;
    _ventasPorCategoria.clear();
    _topProductos.clear();

    Map<String, Producto> mapaProductos = {
      for (var p in _productos) p.id.toString(): p
    };

    for (var venta in _ventas) {
      _totalGeneral += venta.total;
      for (var item in venta.items) {
        String nombre = item['nombre'].toString();
        double subtotal = (item['subtotal'] as num).toDouble();
        int cant = (item['cantidad'] as num).toInt();

        _topProductos[nombre] = (_topProductos[nombre] ?? 0) + subtotal;

        Producto? prod = mapaProductos.values.firstWhere(
          (p) => p.nombre == nombre,
          orElse: () => Producto(
            id: 0, nombre: nombre, codigoBarras: '',
            precioCompra: 0, precioVenta: 0, stock: 0
          )
        );

        String cat = prod.categoria ?? 'Sin categoría';
        _ventasPorCategoria[cat] = (_ventasPorCategoria[cat] ?? 0) + subtotal;
        _costoTotal += prod.precioCompra * cant;
      }
    }

    _gananciaNeta = _totalGeneral - _costoTotal;
  }

  Future<void> _exportarReporteCompleto() async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    final resumen = excel['Resumen'];
    resumen.appendRow(['FACTUCELL — Reporte Completo 🎆']);
    resumen.appendRow(['Fecha generación', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())]);
    resumen.appendRow(['']);
    resumen.appendRow(['TOTAL VENTAS', CurrencyFormatear.monto(_totalGeneral)]);
    resumen.appendRow(['COSTO TOTAL', CurrencyFormatear.monto(_costoTotal)]);
    resumen.appendRow(['GANANCIA NETA', CurrencyFormatear.monto(_gananciaNeta)]);
    resumen.appendRow(['']);
    resumen.appendRow(['VENTAS POR CATEGORÍA']);
    _ventasPorCategoria.forEach((cat, monto) {
      resumen.appendRow([cat, CurrencyFormatear.monto(monto)]);
    });
    resumen.appendRow(['']);
    resumen.appendRow(['PRODUCTOS MÁS VENDIDOS']);
    _topProductos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(10)
      .forEach((e) => resumen.appendRow([e.key, CurrencyFormatear.monto(e.value)]));

    final detalle = excel['Detalle Ventas'];
    detalle.appendRow(['Fecha', 'Producto', 'Cantidad', 'Subtotal', 'Método Pago']);
    for (var v in _ventas) {
      for (var item in v.items) {
        detalle.appendRow([
          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(v.fecha)),
          item['nombre'],
          item['cantidad'],
          item['subtotal'],
          v.metodoPago
        ]);
      }
    }

    final dir = await getTemporaryDirectory();
    final ruta = '${dir.path}/reporte_factucell_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    await excel.save(fileName: ruta);
    await Share.shareXFiles([XFile(ruta)], text: '📊 Reporte Completo — FACTUCELL Pirotecnia 🎆');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Estadísticas 📊'),
        backgroundColor: TemaFactucell.rojoFuego,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportarReporteCompleto,
            tooltip: 'Exportar Reporte',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeAreaPadding(
        child: _cargando
          ? const Center(child: CircularProgressIndicator(color: TemaFactucell.naranjaChispa))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _tarjetaResumen(),
                  const SizedBox(height: 20),
                  _seccionCategorias(),
                  const SizedBox(height: 20),
                  _seccionTopProductos(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaFactucell.naranjaChispa,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _exportarReporteCompleto,
                      icon: const Icon(Icons.file_download, color: Colors.white),
                      label: const Text('Exportar Reporte Completo 📤',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
      ),
      bottomNavigationBar: const SafeBottomBar(indiceActivo: 2),
    );
  }

  Widget _tarjetaResumen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TemaFactucell.rojoFuego, TemaFactucell.naranjaChispa],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('RESUMEN GENERAL', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          _filaResumen('Total Ventas', _totalGeneral, Icons.receipt_long),
          const Divider(color: Colors.white24, height: 24),
          _filaResumen('Costo Total', _costoTotal, Icons.shopping_cart),
          const Divider(color: Colors.white24, height: 24),
          _filaResumen('GANANCIA NETA', _gananciaNeta, Icons.monetization_on, esDestacado: true),
        ],
      ),
    );
  }

  Widget _filaResumen(String etiqueta, double monto, IconData icono, {bool esDestacado = false}) {
    return Row(
      children: [
        Icon(icono, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(etiqueta, style: const TextStyle(color: Colors.white, fontSize: 15))),
        Text(
          CurrencyFormatear.monto(monto),
          style: TextStyle(
            color: Colors.white,
            fontSize: esDestacado ? 20 : 16,
            fontWeight: esDestacado ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _seccionCategorias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📂 Ventas por Categoría', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._ventasPorCategoria.entries.map((e) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(e.key),
            trailing: Text(CurrencyFormatear.monto(e.value),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        )),
        if (_ventasPorCategoria.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sin datos aún', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _seccionTopProductos() {
    final ordenados = _topProductos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = ordenados.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🏆 Productos Más Vendidos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...top10.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final prod = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 3),
            color: idx <= 3 ? TemaFactucell.naranjaChispa.withOpacity(0.08) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: idx == 1 ? Colors.amber : idx == 2 ? Colors.grey[400] : idx == 3 ? Colors.brown[300] : Colors.grey[200],
                child: Text('$idx', style: TextStyle(color: idx <= 3 ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
              ),
              title: Text(prod.key),
              trailing: Text(CurrencyFormatear.monto(prod.value),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }),
        if (top10.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sin datos aún', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }
}

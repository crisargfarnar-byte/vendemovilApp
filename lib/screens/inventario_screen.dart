// ==================================================
// FACTUCELL — Inventario de Productos
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Rubro: Artículos y Juegos Pirotécnicos 🎆
// ==================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/producto.dart';
import 'producto_form_screen.dart';
import '../utils/currency_formatter.dart';
import 'scanner_screen.dart';

class InventarioScreen extends StatefulWidget {
  final String? codigoInicial;
  const InventarioScreen({super.key, this.codigoInicial});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<Producto> _productos = [];
  List<Producto> _filtrados = [];
  bool _cargando = true;
  String _busqueda = '';
  String? _categoriaSeleccionada;

  // 🎇 CATEGORÍAS ESPECÍFICAS DE TU NEGOCIO
  static const List<String> categorias = [
    'Todos',
    'Fuegos Artificiales 🎇',
    'Cohetes y Baterías 🚀',
    'Luces y Chispas ✨',
    'Artículos de Temporada 🎉',
    'Accesorios y Seguridad 🛡️',
  ];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    if (widget.codigoInicial != null && widget.codigoInicial!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscarCodigoInicial());
    }
  }

  Future<void> _cargarProductos() async {
    final lista = await DatabaseService.obtenerTodosProductos();
    setState(() {
      _productos = lista;
      _filtrados = lista;
      _cargando = false;
    });
    _aplicarFiltros();
  }

  void _buscarCodigoInicial() {
    setState(() {
      _busqueda = widget.codigoInicial!;
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    setState(() {
      _filtrados = _productos.where((p) {
        final coincideBusqueda = _busqueda.isEmpty ||
            p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
            p.codigo.contains(_busqueda);
        final coincideCategoria = _categoriaSeleccionada == null ||
            _categoriaSeleccionada == 'Todos' ||
            p.categoria == _categoriaSeleccionada;
        return coincideBusqueda && coincideCategoria;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: TemaFactucell.rojoFuego,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductoFormScreen())).then((_) => _cargarProductos()),
        backgroundColor: TemaFactucell.naranjaChispa,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
      body: Column(
        children: [
          // 🔍 BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (v) { setState(() => _busqueda = v); _aplicarFiltros(); },
            ),
          ),

          // 📂 FILTRO POR CATEGORÍA
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categorias[i];
                final seleccionada = _categoriaSeleccionada == cat || (cat == 'Todos' && _categoriaSeleccionada == null);
                return FilterChip(
                  label: Text(cat),
                  selected: seleccionada,
                  onSelected: (_) {
                    setState(() => _categoriaSeleccionada = cat == 'Todos' ? null : cat);
                    _aplicarFiltros();
                  },
                  selectedColor: TemaFactucell.naranjaChispa.withOpacity(0.3),
                  checkmarkColor: TemaFactucell.rojoFuego,
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 📊 RESUMEN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_filtrados.length} productos', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Total: ${CurrencyFormatear.simbolo} ${_calcularValorTotal().toStringAsFixed(2)}',
                    style: const TextStyle(color: TemaFactucell.naranjaChispa, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 📋 LISTA DE PRODUCTOS
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: TemaFactucell.naranjaChispa))
                : _filtrados.isEmpty
                    ? const Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No hay productos registrados', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('Toca el botón "+" para agregar tu primer producto 🎆', style: TextStyle(color: Colors.grey)),
                        ],
                      ))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtrados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final prod = _filtrados[i];
                          final bajoStock = prod.stock <= 5;
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: prod.imagen != null && prod.imagen!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(File(prod.imagen!), width: 48, height: 48, fit: BoxFit.cover))
                                  : CircleAvatar(
                                      backgroundColor: TemaFactucell.rojoFuego.withOpacity(0.15),
                                      child: const Icon(Icons.local_fireworks, color: TemaFactucell.rojoFuego)),
                              title: Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prod.categoria ?? 'Sin categoría', style: const TextStyle(fontSize: 12)),
                                  Text('Cód: ${prod.codigo} • ${CurrencyFormatear.simbolo} ${prod.precioVenta.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Stock: ${prod.stock}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: bajoStock ? Colors.red : null,
                                      )),
                                  if (bajoStock)
                                    const Text('¡Bajo!', style: TextStyle(color: Colors.red, fontSize: 11)),
                                ],
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: prod))).then((_) => _cargarProductos()),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  double _calcularValorTotal() {
    return _filtrados.fold(0, (sum, p) => sum + (p.precioVenta * p.stock));
  }
}

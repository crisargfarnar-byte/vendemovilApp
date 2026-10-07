// ==================================================
// FACTUCELL — Formulario de Producto
// Versión: 1.0 | Guayaquil, Ecuador 🇪🇨
// Rubro: Artículos y Juegos Pirotécnicos 🎆
// ==================================================

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/producto.dart';
import '../services/database_service.dart';
import '../utils/peso_formatter.dart';
import 'scanner_screen.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;
  final String? codigoBarras;
  const ProductoFormScreen({super.key, this.producto, this.codigoBarras});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreCtrl;
  late TextEditingController _codigoCtrl;
  late TextEditingController _precioCompraCtrl;
  late TextEditingController _precioVentaCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _descripcionCtrl;
  
  String? _categoriaSeleccionada;
  String? _rutaImagen;
  bool _esEdicion = false;
  bool _guardando = false;

  // 🎇 CATEGORÍAS DE TU NEGOCIO
  static const List<String> categorias = [
    'Fuegos Artificiales 🎇',
    'Cohetes y Baterías 🚀',
    'Luces y Chispas ✨',
    'Artículos de Temporada 🎉',
    'Accesorios y Seguridad 🛡️',
  ];

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.producto != null;
    
    _nombreCtrl = TextEditingController(text: widget.producto?.nombre ?? '');
    _codigoCtrl = TextEditingController(
      text: widget.producto?.codigo ?? widget.codigoBarras ?? const Uuid().v4().substring(0, 8).toUpperCase()
    );
    _precioCompraCtrl = TextEditingController(
      text: widget.producto?.precioCompra.toString() ?? ''
    );
    _precioVentaCtrl = TextEditingController(
      text: widget.producto?.precioVenta.toString() ?? ''
    );
    _stockCtrl = TextEditingController(
      text: widget.producto?.stock.toString() ?? '0'
    );
    _descripcionCtrl = TextEditingController(
      text: widget.producto?.descripcion ?? ''
    );
    _categoriaSeleccionada = widget.producto?.categoria ?? categorias.first;
    _rutaImagen = widget.producto?.imagen;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _precioCompraCtrl.dispose();
    _precioVentaCtrl.dispose();
    _stockCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.camera);
    if (imagen != null) {
      setState(() => _rutaImagen = imagen.path);
    }
  }

  Future<void> _escanearCodigo() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen())
    );
    if (resultado != null && resultado is String) {
      setState(() => _codigoCtrl.text = resultado);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final producto = Producto(
      id: _esEdicion ? widget.producto!.id : null,
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoriaSeleccionada,
      precioCompra: double.tryParse(_precioCompraCtrl.text) ?? 0,
      precioVenta: double.parse(_precioVentaCtrl.text),
      stock: int.parse(_stockCtrl.text),
      descripcion: _descripcionCtrl.text.trim(),
      imagen: _rutaImagen,
      fechaCreacion: _esEdicion ? widget.producto!.fechaCreacion : DateTime.now().toIso8601String(),
      fechaActualizacion: DateTime.now().toIso8601String(),
    );

    try {
      if (_esEdicion) {
        await DatabaseService.actualizarProducto(producto);
      } else {
        await DatabaseService.agregarProducto(producto);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Producto' : 'Nuevo Producto'),
        backgroundColor: TemaFactucell.rojoFuego,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _escanearCodigo,
            tooltip: 'Escanear código',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🖼️ IMAGEN DEL PRODUCTO
              Center(
                child: GestureDetector(
                  onTap: _seleccionarImagen,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TemaFactucell.naranjaChispa, width: 2),
                    ),
                    child: _rutaImagen != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(File(_rutaImagen!), fit: BoxFit.cover)
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 42, color: TemaFactucell.naranjaChispa),
                              SizedBox(height: 6),
                              Text('Subir foto', style: TextStyle(color: TemaFactucell.naranjaChispa))
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🏷️ CÓDIGO
              TextFormField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un código' : null,
              ),
              const SizedBox(height: 16),

              // 📝 NOMBRE
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto',
                  prefixIcon: Icon(Icons.local_fireworks),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),

              // 📂 CATEGORÍA
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (v) => setState(() => _categoriaSeleccionada = v),
              ),
              const SizedBox(height: 16),

              // 💰 PRECIOS
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioCompraCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Costo \$',
                        prefixIcon: Icon(Icons.trending_down),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _precioVentaCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio Venta \$',
                        prefixIcon: Icon(Icons.trending_up, color: TemaFactucell.rojoFuego),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 📦 STOCK
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad en Stock',
                  prefixIcon: Icon(Icons.inventory_2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el stock';
                  if (int.tryParse(v) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 📄 DESCRIPCIÓN
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción / Observaciones',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 28),

              // ✅ BOTÓN GUARDAR
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaFactucell.naranjaChispa,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _esEdicion ? 'Actualizar Producto' : 'Guardar Producto',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

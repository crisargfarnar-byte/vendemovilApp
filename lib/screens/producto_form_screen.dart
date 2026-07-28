import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/producto.dart';
import '../services/database_service.dart';
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
  final _db = DatabaseService.instance;
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _precioCompraCtrl;
  late final TextEditingController _precioVentaCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _stockMinimoCtrl;
  String? _categoriaSeleccionada;
  List<String> _categorias = [];
  String? _imagenUrl;
  bool _isEditing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.producto != null;
    final p = widget.producto;
    _codigoCtrl = TextEditingController(text: p?.codigoBarras ?? widget.codigoBarras ?? '');
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCompraCtrl = TextEditingController(text: p != null ? p.precioCompra.toStringAsFixed(2) : '');
    _precioVentaCtrl = TextEditingController(text: p != null ? p.precioVenta.toStringAsFixed(2) : '');
    _stockCtrl = TextEditingController(text: p != null ? '${p.stock}' : '');
    _stockMinimoCtrl = TextEditingController(text: p != null ? '${p.stockMinimo}' : '5');
    _categoriaSeleccionada = p?.categoria;
    _imagenUrl = p?.imagenUrl;
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final cats = await _db.obtenerCategorias();
    if (mounted) setState(() => _categorias = cats);
  }

  Future<void> _escanear() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen(titulo: 'Escanear Código')),
    );
    if (codigo != null) {
      if (_codigoCtrl.text.trim().isEmpty) {
        _codigoCtrl.text = codigo;
      } else {
        if (!_codigoCtrl.text.contains(codigo)) {
          _codigoCtrl.text = '${_codigoCtrl.text.trim()}, $codigo';
        }
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagenUrl = image.path);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final producto = Producto(
        id: widget.producto?.id ?? const Uuid().v4(),
        codigoBarras: _codigoCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        categoria: _categoriaSeleccionada,
        precioCompra: double.tryParse(_precioCompraCtrl.text) ?? 0,
        precioVenta: double.parse(_precioVentaCtrl.text),
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        stockMinimo: int.tryParse(_stockMinimoCtrl.text) ?? 5,
        imagenUrl: _imagenUrl,
        fechaCreacion: widget.producto?.fechaCreacion,
      );
      if (_isEditing) {
        await _db.actualizarProducto(producto);
      } else {
        await _db.insertarProducto(producto);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? '✓ Producto actualizado' : '✓ Producto guardado'),
          backgroundColor: AppTheme.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _eliminar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Eliminar "${widget.producto!.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.eliminarProducto(widget.producto!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado'), backgroundColor: AppTheme.error),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _asociarAProductoExistente() async {
    final productos = await _db.obtenerProductos();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            final filtrados = productos.where((p) => 
              p.nombre.toLowerCase().contains(searchQuery.toLowerCase()) || 
              p.codigoBarras.contains(searchQuery)
            ).toList();
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('Vincular a producto existente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Busca y selecciona el producto al que quieres añadir este nuevo código.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => setStateModal(() => searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtrados.isEmpty
                        ? const Center(child: Text('No hay productos que coincidan.'))
                        : ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (_, i) {
                              final p = filtrados[i];
                          return ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 20),
                            ),
                            title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Stock: ${p.stock} | Cód: ${p.codigoBarras.split(',').first}..', style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.link, color: AppTheme.primary),
                            onTap: () async {
                              Navigator.pop(ctx);
                              if (!p.codigoBarras.contains(widget.codigoBarras!)) {
                                final pActualizado = p.copyWith(
                                  codigoBarras: '${p.codigoBarras}, ${widget.codigoBarras!}',
                                );
                                await _db.actualizarProducto(pActualizado);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Código vinculado a ${p.nombre}'), backgroundColor: AppTheme.success),
                                  );
                                  Navigator.pop(context); // Cierra el formulario de "Nuevo producto"
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Este código ya estaba vinculado a este producto.')),
                                  );
                                  Navigator.pop(context);
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error), onPressed: _eliminar),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.bgGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    image: _imagenUrl != null
                        ? DecorationImage(image: FileImage(File(_imagenUrl!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imagenUrl == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: AppTheme.textSecondary, size: 32),
                            SizedBox(height: 8),
                            Text('Añadir foto', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildLabel('Código de Barras'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codigoCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej: 7750... o varios separados por coma', 
                      prefixIcon: Icon(Icons.qr_code)
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Ingresa el código' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                    onPressed: _escanear,
                  ),
                ),
              ],
            ),
            if (!_isEditing && widget.codigoBarras != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _asociarAProductoExistente,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Vincular a producto existente'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ),
            ],
            const SizedBox(height: 16),

            _buildLabel('Nombre del Producto'),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(hintText: 'Ej: Inca Kola 500ml', prefixIcon: Icon(Icons.inventory_2_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Ingresa el nombre' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            _buildLabel('Descripción (opcional)'),
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(hintText: 'Descripción breve...'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            _buildLabel('Categoría'),
            DropdownButtonFormField<String>(
              initialValue: _categoriaSeleccionada,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
              hint: const Text('Seleccionar categoría'),
              items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categoriaSeleccionada = v),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Precio Compra (S/)'),
                      TextFormField(
                        controller: _precioCompraCtrl,
                        decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.money_off_outlined)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Precio Venta (S/)'),
                      TextFormField(
                        controller: _precioVentaCtrl,
                        decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.attach_money)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v == null || v.isEmpty || (double.tryParse(v) ?? 0) <= 0 ? 'Precio inválido' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Stock Actual'),
                      TextFormField(
                        controller: _stockCtrl,
                        decoration: const InputDecoration(hintText: '0', prefixIcon: Icon(Icons.numbers)),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Stock Mínimo'),
                      TextFormField(
                        controller: _stockMinimoCtrl,
                        decoration: const InputDecoration(hintText: '5', prefixIcon: Icon(Icons.warning_amber)),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _guardar,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Guardando...' : (_isEditing ? 'Actualizar Producto' : 'Guardar Producto')),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
    );
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCompraCtrl.dispose();
    _precioVentaCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinimoCtrl.dispose();
    super.dispose();
  }
}

/// Modelo de Producto para inventario
class Producto {
  final String id;
  final String codigoBarras;
  final String nombre;
  final String? descripcion;
  final String? categoria;
  final double precioCompra;
  final double precioVenta;
  final int stock;
  final int stockMinimo;
  final String? imagenUrl;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Producto({
    required this.id,
    required this.codigoBarras,
    required this.nombre,
    this.descripcion,
    this.categoria,
    required this.precioCompra,
    required this.precioVenta,
    required this.stock,
    this.stockMinimo = 5,
    this.imagenUrl,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        fechaActualizacion = fechaActualizacion ?? DateTime.now();

  /// Ganancia unitaria
  double get ganancia => precioVenta - precioCompra;

  /// Margen de ganancia en porcentaje
  double get margenGanancia =>
      precioCompra > 0 ? ((ganancia / precioCompra) * 100) : 0;

  /// Si el stock está bajo
  bool get stockBajo => stock <= stockMinimo;

  /// Si está agotado
  bool get agotado => stock <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo_barras': codigoBarras,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'imagen_url': imagenUrl,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as String,
      codigoBarras: map['codigo_barras'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      categoria: map['categoria'] as String?,
      precioCompra: (map['precio_compra'] as num).toDouble(),
      precioVenta: (map['precio_venta'] as num).toDouble(),
      stock: map['stock'] as int,
      stockMinimo: map['stock_minimo'] as int? ?? 5,
      imagenUrl: map['imagen_url'] as String?,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      fechaActualizacion: DateTime.parse(map['fecha_actualizacion'] as String),
    );
  }

  Producto copyWith({
    String? id,
    String? codigoBarras,
    String? nombre,
    String? descripcion,
    String? categoria,
    double? precioCompra,
    double? precioVenta,
    int? stock,
    int? stockMinimo,
    String? imagenUrl,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Producto(
      id: id ?? this.id,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}

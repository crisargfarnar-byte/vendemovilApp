/// Modelo de Venta
class Venta {
  final String id;
  final List<ItemVenta> items;
  final double subtotal;
  final double descuento;
  final double total;
  final String metodoPago; // 'efectivo', 'yape', 'plin', 'tarjeta'
  final double? montoPagado;
  final double? vuelto;
  final DateTime fecha;
  final String? nota;

  Venta({
    required this.id,
    required this.items,
    required this.subtotal,
    this.descuento = 0,
    required this.total,
    required this.metodoPago,
    this.montoPagado,
    this.vuelto,
    DateTime? fecha,
    this.nota,
  }) : fecha = fecha ?? DateTime.now();

  int get totalItems => items.fold(0, (sum, item) => sum + item.cantidad);

  double get gananciaTotal =>
      items.fold(0.0, (sum, item) => sum + item.gananciaTotal) - descuento;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'metodo_pago': metodoPago,
      'monto_pagado': montoPagado,
      'vuelto': vuelto,
      'fecha': fecha.toIso8601String(),
      'nota': nota,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map, List<ItemVenta> items) {
    return Venta(
      id: map['id'] as String,
      items: items,
      subtotal: (map['subtotal'] as num).toDouble(),
      descuento: (map['descuento'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num).toDouble(),
      metodoPago: map['metodo_pago'] as String,
      montoPagado: (map['monto_pagado'] as num?)?.toDouble(),
      vuelto: (map['vuelto'] as num?)?.toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      nota: map['nota'] as String?,
    );
  }
}

/// Item individual dentro de una venta
class ItemVenta {
  final String id;
  final String ventaId;
  final String productoId;
  final String productoNombre;
  final String codigoBarras;
  final double precioUnitario;
  final double precioCompra;
  final int cantidad;
  final double subtotal;
  final String? imagenUrl;

  ItemVenta({
    required this.id,
    required this.ventaId,
    required this.productoId,
    required this.productoNombre,
    required this.codigoBarras,
    required this.precioUnitario,
    required this.precioCompra,
    required this.cantidad,
    required this.subtotal,
    this.imagenUrl,
  });

  double get gananciaUnitaria => precioUnitario - precioCompra;
  double get gananciaTotal => gananciaUnitaria * cantidad;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'producto_nombre': productoNombre,
      'codigo_barras': codigoBarras,
      'precio_unitario': precioUnitario,
      'precio_compra': precioCompra,
      'cantidad': cantidad,
      'subtotal': subtotal,
    };
  }

  factory ItemVenta.fromMap(Map<String, dynamic> map) {
    return ItemVenta(
      id: map['id'] as String,
      ventaId: map['venta_id'] as String,
      productoId: map['producto_id'] as String,
      productoNombre: map['producto_nombre'] as String,
      codigoBarras: map['codigo_barras'] as String? ?? '',
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      precioCompra: (map['precio_compra'] as num).toDouble(),
      cantidad: map['cantidad'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  ItemVenta copyWith({
    int? cantidad,
    double? subtotal,
  }) {
    return ItemVenta(
      id: id,
      ventaId: ventaId,
      productoId: productoId,
      productoNombre: productoNombre,
      codigoBarras: codigoBarras,
      precioUnitario: precioUnitario,
      precioCompra: precioCompra,
      cantidad: cantidad ?? this.cantidad,
      subtotal: subtotal ?? this.subtotal,
      imagenUrl: imagenUrl,
    );
  }
}

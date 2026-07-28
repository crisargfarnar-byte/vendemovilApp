import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../models/venta.dart';
import '../utils/currency_formatter.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._();
  PrinterService._();

  String _monedaSimbolo = 'S/';
  String _nombreNegocio = 'VENDE MÓVIL';
  String _direccion = '';
  String _telefono = '';
  String _ruc = '';
  String _mensajePie = '¡Gracias por su compra!';
  double _anchoPapel = 58.0;
  String? _impresoraMac;
  String? _impresoraNombre;
  String? _vendedor;

  String _stripAccents(String str) {
    return str
        .replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u')
        .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
        .replaceAll('ñ', 'n').replaceAll('Ñ', 'N');
  }

  String _formatMoney(double amount) {
    return CurrencyFormatter.format(amount, _monedaSimbolo);
  }

  void configurar({String? nombre, String? direccion, String? telefono, String? ruc, String? mensaje, double? anchoPapel, String? mac, String? printerName, String? moneda, String? vendedor}) {
    if (nombre != null) _nombreNegocio = nombre;
    if (direccion != null) _direccion = direccion;
    if (telefono != null) _telefono = telefono;
    if (ruc != null) _ruc = ruc;
    if (mensaje != null) _mensajePie = mensaje;
    if (anchoPapel != null) _anchoPapel = anchoPapel;
    if (mac != null) _impresoraMac = mac;
    if (printerName != null) _impresoraNombre = printerName;
    if (moneda != null) _monedaSimbolo = moneda;
    if (vendedor != null) _vendedor = vendedor;
  }

  String? get impresoraNombre => _impresoraNombre;
  String? get impresoraMac => _impresoraMac;

  Future<void> imprimirTicket(Venta venta, {String? macOverride}) async {
    final mac = macOverride ?? _impresoraMac;
    if (mac == null || mac.isEmpty) {
      throw Exception('No hay impresora configurada');
    }

    final conectado = await PrintBluetoothThermal.connectionStatus;
    if (!conectado) {
      final res = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (!res) throw Exception('No se pudo conectar a la impresora');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(_anchoPapel == 80.0 ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    // Formato de fecha
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'es');

    // Cabecera
    bytes += generator.text(_stripAccents(_nombreNegocio), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    if (_ruc.isNotEmpty) bytes += generator.text('RUC: $_ruc', styles: const PosStyles(align: PosAlign.center));
    if (_direccion.isNotEmpty) bytes += generator.text(_stripAccents(_direccion), styles: const PosStyles(align: PosAlign.center));
    if (_telefono.isNotEmpty) bytes += generator.text('Tel: $_telefono', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.emptyLines(1);
    bytes += generator.hr();
    
    // Info venta
    bytes += generator.row([
      PosColumn(text: 'Boleta', width: 6),
      PosColumn(text: '#${venta.id.substring(0, 8).toUpperCase()}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Fecha', width: 6),
      PosColumn(text: dateFormat.format(venta.fecha), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (_vendedor != null && _vendedor!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Atendido por', width: 6),
        PosColumn(text: _vendedor!, width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    
    bytes += generator.hr();

    // Items Header - Ajustando el tamaño para mejor legibilidad
    bytes += generator.row([
      PosColumn(text: 'Cant', width: 2, styles: const PosStyles(bold: true, align: PosAlign.left)),
      PosColumn(text: 'Producto', width: 6, styles: const PosStyles(bold: true, align: PosAlign.left)),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    // Items
    for (var item in venta.items) {
      String prod = _stripAccents(item.productoNombre);
      if (prod.length > 14) prod = prod.substring(0, 14);

      bytes += generator.row([
        PosColumn(text: '${item.cantidad}', width: 2, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: prod, width: 6, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: _formatMoney(item.subtotal), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
      // Imprimir el PU debajo si se desea mayor detalle, o simplemente omitirlo para mantenerlo limpio
    }
    
    bytes += generator.hr();
    
    // Totales
    if (venta.descuento > 0) {
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 6),
        PosColumn(text: _formatMoney(venta.subtotal), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Descuento:', width: 6),
        PosColumn(text: '-${_formatMoney(venta.descuento)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: _formatMoney(venta.total), width: 6, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    
    bytes += generator.emptyLines(1);
    bytes += generator.row([
      PosColumn(text: 'Pago:', width: 6),
      PosColumn(text: _metodoPagoLabel(venta.metodoPago), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    if (venta.montoPagado != null) {
      bytes += generator.row([
        PosColumn(text: 'Pago con:', width: 6),
        PosColumn(text: _formatMoney(venta.montoPagado!), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (venta.vuelto != null && venta.vuelto! > 0) {
      bytes += generator.row([
        PosColumn(text: 'Vuelto:', width: 6),
        PosColumn(text: _formatMoney(venta.vuelto!), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.emptyLines(1);
    bytes += generator.hr(ch: '-');
    bytes += generator.text(_stripAccents(_mensajePie), styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Vende Movil v1.0', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(2);
    bytes += generator.cut();

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  String _metodoPagoLabel(String metodo) {
    switch (metodo) {
      case 'efectivo': return 'Efectivo';
      case 'yape': return 'Yape';
      case 'plin': return 'Plin';
      case 'tarjeta': return 'Tarjeta';
      default: return metodo;
    }
  }

  Future<List<BluetoothInfo>> obtenerImpresoras() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }
}

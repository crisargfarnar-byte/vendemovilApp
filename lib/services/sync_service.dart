import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  static String get _baseUrl => AppConfig.syncBaseUrl;

  static Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  /// Uploads all local data to the server
  static Future<bool> uploadToCloud() async {
    try {
      final email = await _getUserEmail();
      if (email == null) return false;

      final dbService = DatabaseService.instance;
      
      final productos = (await dbService.obtenerProductos()).map((p) => p.toMap()).toList();
      // To get raw ventas including all fields we can extract from db or use serialization
      // For simplicity let's use the DB raw queries or the object toMap
      
      final db = await dbService.database;
      final ventasMaps = await db.query('ventas');
      final itemsVentaMaps = await db.query('items_venta');
      final categoriasMaps = await db.query('categorias');

      final payload = {
        'productos': productos,
        'ventas': ventasMaps,
        'items_venta': itemsVentaMaps,
        'categorias': categoriasMaps,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/upload'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': email,
        },
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading to cloud: $e');
      return false;
    }
  }

  /// Downloads data from the server and replaces local data
  static Future<bool> downloadFromCloud() async {
    try {
      final email = await _getUserEmail();
      if (email == null) return false;

      final response = await http.get(
        Uri.parse('$_baseUrl/download'),
        headers: {
          'x-user-email': email,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dbService = DatabaseService.instance;
        final db = await dbService.database;
        
        await db.transaction((txn) async {
          // Clear current tables
          await txn.delete('productos');
          await txn.delete('ventas');
          await txn.delete('items_venta');
          await txn.delete('categorias');

          // Insert fetched data
          final List productos = data['productos'] ?? [];
          for (var p in productos) {
            // Remove server-specific fields before inserting to sqlite
            p.remove('user_email');
            await txn.insert('productos', p);
          }

          final List ventas = data['ventas'] ?? [];
          for (var v in ventas) {
            v.remove('user_email');
            await txn.insert('ventas', v);
          }

          final List items = data['items_venta'] ?? [];
          for (var i in items) {
            i.remove('user_email');
            await txn.insert('items_venta', i);
          }

          final List categorias = data['categorias'] ?? [];
          for (var c in categorias) {
            c.remove('user_email');
            await txn.insert('categorias', c);
          }
        });

        return true;
      }
      return false;
    } catch (e) {
      print('Error downloading from cloud: $e');
      return false;
    }
  }

  /// Tells the server to delete all data for this user
  static Future<bool> deleteFromCloud() async {
    try {
      final email = await _getUserEmail();
      if (email == null) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/delete'),
        headers: {
          'x-user-email': email,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting from cloud: $e');
      return false;
    }
  }

  /// Utility to sync data on every save if Nube plan is active
  /// In a production environment, you might use background queues
  static Future<void> syncIfNube() async {
    // For now we do a full upload, but ideally it should be differential
    // To avoid lag, we won't block UI
    uploadToCloud();
  }
}

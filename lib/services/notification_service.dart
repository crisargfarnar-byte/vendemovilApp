import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/app_config.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String get _baseUrl => AppConfig.userApiBaseUrl;

  static Future<void> init() async {
    // Solicitar permisos en iOS y Android 13+
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveTokenToServer(token);
      }

      // Escuchar cuando el token se refresque
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToServer(newToken);
      });
    }
  }

  static Future<void> _saveTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      
      if (email == null || email.isEmpty) return;

      // Send the token to VPS
      await http.post(
        Uri.parse('$_baseUrl/token'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-email': email,
        },
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (e) {
      print('Error guardando FCM token en servidor: $e');
    }
  }
}


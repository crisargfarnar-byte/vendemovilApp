/// Configuración de backend. En desarrollo/producción usa:
/// `flutter run --dart-define=API_BASE_URL=http://tu-servidor:3000`
class AppConfig {
  static const String apiHost = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static String get syncBaseUrl => '$apiHost/api/sync';
  static String get userApiBaseUrl => '$apiHost/api/user';
}

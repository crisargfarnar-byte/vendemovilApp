# vendemovilApp (Vende Más)

App Flutter POS: escáner de código de barras, impresión térmica, sync con backend y Firebase Auth.

## Configuración local

### Firebase

1. Instala FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Ejecuta `flutterfire configure` en la raíz del proyecto  
   O copia los ejemplos y rellena tus valores:
   - `lib/firebase_options.example.dart` → `lib/firebase_options.dart`
   - `android/app/google-services.json.example` → `android/app/google-services.json`
   - `firebase.json.example` → `firebase.json`

### API del backend (VPS)

Por defecto apunta a `http://localhost:3000`. Para tu servidor:

```bash
flutter run --dart-define=API_BASE_URL=http://TU_SERVIDOR:3000
```

### Dependencias

```bash
flutter pub get
flutter run
```

## Archivos que no van al repositorio

Claves privadas (`.pem`), `google-services.json`, `firebase_options.dart`, `firebase.json` y `.env` están en `.gitignore`. Mantén copias locales seguras.

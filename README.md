# Vende Móvil

POS Flutter (Android + iOS): venta por unidad o kilos, escáner, tickets térmicos y WhatsApp.

**Versión:** 2.0.0+2  
**Bundle / applicationId:** `com.vendemovil`

App 100% local en el dispositivo. Sin Firebase ni servidor.

## Codemagic (iOS)

1. En [Codemagic](https://codemagic.io) conecta el repo [rossellmestanza/vendemovilApp](https://github.com/rossellmestanza/vendemovilApp).
2. Usa el archivo `codemagic.yaml` de la raíz.
3. Workflows:
   - **iOS Compile (sin firmar):** comprueba que el proyecto compile.
   - **iOS IPA App Store:** genera el `.ipa` firmado.
4. Para el IPA, en Codemagic → **Code signing identities**:
   - Conecta tu cuenta de Apple Developer.
   - Bundle ID: `com.vendemovil`
   - Distribution: App Store
5. Crea el App ID `com.vendemovil` en [Apple Developer](https://developer.apple.com) si aún no existe.

## Local

```bash
flutter pub get
flutter run
```

Android release (con `android/key.properties` y el `.jks` locales, no van al repo):

```bash
flutter build apk --release
```

## Permisos iOS

Cámara (escáner), fotos (QR Yape/Plin), Bluetooth (impresora) y ubicación para BLE.

## Secretos

No se suben: `key.properties`, keystores, `.env`, `google-services.json`.

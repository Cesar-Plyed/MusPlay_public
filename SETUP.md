# MusPlay — Setup Guide

## Cambios en esta versión
- ✅ Firebase Storage → **Google Drive** (carpeta `MusPlayFiles`)
- ✅ Anuncios desactivados automáticamente para usuarios Premium/Pro
- ✅ Planes actualizados con permisos de subida y escucha en nube
- ✅ Sobreescritura automática si el archivo ya existe en Drive

---

## 1. Configurar Google Drive API

1. Ve a [console.cloud.google.com](https://console.cloud.google.com)
2. Crea o selecciona tu proyecto
3. Activa la **Google Drive API**:
   - APIs y Servicios → Biblioteca → busca "Google Drive API" → Activar
4. En **APIs y Servicios → Credenciales**:
   - Ya tienes un OAuth client ID (el mismo que usas para Firebase Google Sign-In)
   - Solo necesitas agregar el scope `drive.file` — ya está en el código

5. En `android/app/src/main/AndroidManifest.xml` verifica que tengas:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 2. Instalar dependencias

```bash
flutter pub get
```

---

## 3. Configurar AdMob (IDs reales)

En `lib/features/ads/ad_manager.dart` reemplaza:
```dart
// Por tus IDs reales de admob.google.com:
static const String _bannerAdUnitId = 'ca-app-pub-TUAPP/TUBANNER';
static const String _interstitialAdUnitId = 'ca-app-pub-TUAPP/TUINTERSTITIAL';
```

Y en `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-TUAPPID~TUNUMEROID"/>
```

---

## 4. Correr en dispositivo Android

```bash
flutter run
```

---

## Cómo funciona Google Drive en la app

1. Usuario toca "Mi Nube" → se le pide conectar su Google Drive
2. Se crea/detecta carpeta `MusPlayFiles` en su Drive
3. Sube MP3s → se guardan en esa carpeta
4. Si sube el mismo archivo, se **sobreescribe** automáticamente
5. Al reproducir, se descarga temporalmente al caché del teléfono
6. Solo el usuario dueño del Drive puede ver sus archivos

## Límites por plan

| Plan | Drive | Anuncios | Subida |
|------|-------|----------|--------|
| Gratis | — | Sí | ❌ |
| Premium $49 MXN | 10 GB | No | ✅ |
| Pro $99 MXN | 50 GB | No | ✅ |

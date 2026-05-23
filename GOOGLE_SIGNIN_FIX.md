# 🔧 Solución: Errores de Google Sign In en Android

## 📋 Resumen del Problema

Estabas recibiendo errores al iniciar sesión con Google porque **faltaba el Web Client ID** (también llamado `serverClientId`) en la configuración de GoogleSignIn para Android.

## 🔍 Problemas Encontrados y Solucionados

### ✅ 1. Faltaba `serverClientId` en GoogleSignIn

**Antes:**

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
```

**Después:**

```dart
late final GoogleSignIn _googleSignIn;

GoogleSignInService() {
  _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: EnvConfig.googleWebClientId.isNotEmpty
        ? EnvConfig.googleWebClientId
        : null,
  );
}
```

**Archivos actualizados:**

- `lib/services/auth_service.dart`
- `lib/services/google_drive_service.dart`

### ✅ 2. Agregada nueva variable de entorno

- `lib/core/config/env_config.dart` → `googleWebClientId`

### ✅ 3. Documentación actualizada

- `ENV_SETUP.md` → Instrucciones completas
- `example.env` → Variable de ejemplo

## 🚀 Pasos para Solucionar

### 1️⃣ Obtener el Web Client ID

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto Firebase (`musplay-fe786`)
3. **APIs y Servicios → Credenciales**
4. Busca el OAuth Client ID de tipo **"Web application"**

   Si no existe, créalo:
   - Clic en "+ Crear credenciales"
   - Selecciona "OAuth Client ID"
   - Tipo: "Web application"

5. Copia el **Client ID** completo:
   - Formato: `918279014967-xxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com`

### 2️⃣ Actualizar el archivo `.env`

En la raíz del proyecto, abre `.env` y agrega:

```env
GOOGLE_WEB_CLIENT_ID=918279014967-xxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

**Importante:** Reemplaza con tu Client ID real.

### 3️⃣ Limpiar y ejecutar

```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Ahora Debería Funcionar

- ✅ Google Sign In en Android
- ✅ Google Drive Integration
- ✅ Firebase Authentication

## 🔒 Seguridad

- El archivo `.env` **NO** se subirá al repositorio (está en `.gitignore`)
- Cada desarrollador tiene su propia copia de `.env`
- El Web Client ID es seguro compartir en `.env` (es público en Google Cloud Console)

## 🆘 Si Sigue sin Funcionar

### Posibles causas adicionales:

1. **Package ID incorrecto en Android**
   - Abre `android/app/build.gradle.kts`
   - Verifica que `applicationId = "com.example.musplay"` coincida con el de Google Cloud Console
   - Si usas un package ID diferente, debes regenerar `google-services.json`

2. **`google-services.json` incorrecto**
   - Descárgalo nuevamente de Firebase Console
   - Guárdalo en `android/app/google-services.json`
   - Ejecuta `flutter clean`

3. **Archivo `.env` no cargado**
   - Verifica que existe en la raíz del proyecto
   - Asegúrate de que está agregado en `pubspec.yaml` como asset

4. **Debug keystore SHA-1 incorrecto**
   - Firebase puede requerir tu debug SHA-1
   - Genéralo con:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - Agrega el SHA-1 a Firebase Console → Project Settings → Android

## 📚 Documentación

- [ENV_SETUP.md](ENV_SETUP.md) - Configuración de variables de entorno
- [SETUP.md](SETUP.md) - Setup general del proyecto
- [Google Sign In Flutter Docs](https://pub.dev/packages/google_sign_in)

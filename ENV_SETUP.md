# Configuración de Variables de Entorno (.env)

Este proyecto utiliza variables de entorno para almacenar credenciales sensibles de Firebase que NO deben estar en el repositorio público.

## Configuración Inicial

### 1. Crear el archivo `.env`

En la raíz del proyecto, crea un archivo llamado `.env` con tus credenciales de Firebase:

```
# Firebase Configuration - Android
FIREBASE_API_KEY_ANDROID=tu_api_key_aqui
FIREBASE_APP_ID_ANDROID=tu_app_id_aqui
FIREBASE_MESSAGING_SENDER_ID=tu_sender_id_aqui
FIREBASE_PROJECT_ID=tu_project_id
FIREBASE_STORAGE_BUCKET=tu_storage_bucket

# Firebase Configuration - iOS
FIREBASE_API_KEY_IOS=tu_api_key_ios_aqui
FIREBASE_APP_ID_IOS=tu_app_id_ios_aqui
FIREBASE_IOS_CLIENT_ID=tu_client_id_ios_aqui
FIREBASE_IOS_BUNDLE_ID=com.example.musplay

# Firebase Configuration - Web
FIREBASE_API_KEY_WEB=tu_api_key_web_aqui
FIREBASE_APP_ID_WEB=tu_app_id_web_aqui
FIREBASE_AUTH_DOMAIN=tu_project.firebaseapp.com
FIREBASE_MEASUREMENT_ID_WEB=tu_measurement_id

# Firebase Configuration - Windows
FIREBASE_API_KEY_WINDOWS=tu_api_key_windows_aqui
FIREBASE_APP_ID_WINDOWS=tu_app_id_windows_aqui
FIREBASE_MEASUREMENT_ID_WINDOWS=tu_measurement_id_windows

# Firebase Configuration - macOS
FIREBASE_API_KEY_MACOS=tu_api_key_macos_aqui
FIREBASE_APP_ID_MACOS=tu_app_id_macos_aqui

# Google Sign In - Web Client ID (⚠️ CRÍTICO PARA ANDROID)
# Este es el OAuth Client ID de tipo "Web application" de Google Cloud Console
# Sin este valor, Google Sign In NO funcionará en Android
GOOGLE_WEB_CLIENT_ID=918279014967-xxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

### 2. Obtener las Credenciales de Firebase

Para obtener estas credenciales:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. En Configuración del proyecto → Claves API, encontrarás las claves
4. Para cada plataforma (Android, iOS, Web), tendrás claves diferentes

### 2b. Obtener el Google Web Client ID (IMPORTANTE PARA ANDROID)

⚠️ **Sin este valor, Google Sign In no funcionará en Android**

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona el proyecto de Firebase (ej: musplay-fe786)
3. Ve a **APIs y Servicios → Credenciales**
4. Busca un OAuth Client ID de tipo **"Web application"**
5. Si no existe, crea uno nuevo:
   - Clic en "+ Crear credenciales"
   - Selecciona "OAuth Client ID"
   - Tipo: "Web application"
6. Copia el **Client ID** (tendrá el formato: `918279014967-xxxxxxxxxxxx.apps.googleusercontent.com`)
7. Pégalo en tu `.env` como `GOOGLE_WEB_CLIENT_ID=...`

### 3. Seguridad

⚠️ **IMPORTANTE:**

- El archivo `.env` está en `.gitignore` y NO se subirá al repositorio
- Nunca compartas el archivo `.env` públicamente
- Cada desarrollador debe tener su propio archivo `.env` con sus credenciales
- Si trabajas en equipo, comparte las credenciales de forma segura (ej: 1Password, LastPass, etc.)

### 4. Uso en el Código

El archivo `lib/core/config/env_config.dart` carga automáticamente las variables:

```dart
import 'core/config/env_config.dart';

// Acceder a las variables:
String apiKey = EnvConfig.firebaseApiKeyAndroid;
String projectId = EnvConfig.firebaseProjectId;
```

## Para Nuevos Desarrolladores

Cuando un nuevo desarrollador clone el proyecto:

1. Clona el repositorio
2. Crea un archivo `.env` en la raíz con las credenciales compartidas de forma segura
3. Ejecuta `flutter pub get`
4. ¡Listo!

## Troubleshooting

Si reciben errores sobre "Firebase options not found":

- Verifica que el archivo `.env` existe en la raíz del proyecto
- Verifica que las credenciales están correctas
- Ejecuta `flutter clean && flutter pub get`

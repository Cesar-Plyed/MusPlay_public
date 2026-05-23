# MusPlay

Reproductor de musica para Android construido con Flutter. Permite reproducir archivos de audio almacenados localmente o en Google Drive, con soporte para playlists, autenticacion con Firebase y reproduccion en segundo plano.

Puedes probarlo sin descargar nada: [Demo en Appetize](https://appetize.io/app/b_b4eluz72bsvtkppjvqt7ckdrzi)

---

## Caracteristicas

- Reproduccion de audio local y desde Google Drive
- Controles de reproduccion en segundo plano con notificacion de media
- Autenticacion con Google y Email/Password via Firebase Auth
- Modo invitado sin cuenta
- Playlists personalizadas almacenadas en Firestore
- Sincronizacion de archivos con Google Drive (carpeta `MusPlayFiles`)
- Restauracion automatica de la ultima cancion al abrir la app
- Planes de suscripcion (en desarrollo)
- Tema oscuro

---

## Tecnologias

| Categoria | Tecnologia |
|---|---|
| Framework | Flutter 3.44 (Dart) |
| Autenticacion | Firebase Auth |
| Base de datos | Cloud Firestore |
| Almacenamiento | Firebase Storage |
| Nube de musica | Google Drive API v3 |
| Reproduccion | just_audio + audio_service |
| Estado | Provider |
| Variables de entorno | flutter_dotenv |

---

## Estructura del proyecto

```
lib/
  cloud/
    presentation/
      cloud_library_screen.dart     # Pantalla de biblioteca en Google Drive
  core/
    config/
      env_config.dart               # Carga de variables de entorno
    models/
      cloud_song.dart               # Modelo de cancion en Drive
    providers/
      firestore_providers.dart
      storage_provider.dart
      subscription_provider.dart
    theme/
      app_theme.dart                # Tema oscuro global
  features/
    library/
      presentation/
        library_screen.dart         # Biblioteca local
    player/
      domain/
        song.dart                   # Modelo de cancion
      presentation/
        player_screen.dart          # Pantalla del reproductor
        widgets/
          album_art_widget.dart
          player_controls_widget.dart
          progress_bar_widget.dart
    playlists/
      presentation/
        playlists_screen.dart
        playlist_detail_screen.dart
        add_to_playlist_sheet.dart
      providers/
        playlist_provider.dart
    subscriptions/
      presentation/
        subscription_plans_screen.dart
  models/
    playlist_model.dart
    playlist_song.dart
    song_model.dart
    subscription_plan.dart
    user_model.dart
  services/
    auth/
      presentation/
        login_screen.dart
    auth_service.dart               # Google Sign In + Email/Password
    audio_handler.dart              # Manejo de audio en background
    firestore_service.dart
    google_drive_service.dart       # Integracion con Google Drive
    preferences_service.dart        # Persistencia local (SharedPreferences)
    storage_service.dart
  shared/
    widgets/
      terms_dialog.dart
  firebase_options.dart
  main.dart
```

---

## Configuracion inicial

### Requisitos

- Flutter 3.44 o superior
- Android SDK 35+
- Cuenta de Firebase
- Java 17 o 21

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/musplay.git
cd musplay
```

### 2. Configurar variables de entorno

Crea un archivo `.env` en la raiz del proyecto basandote en `.env.example`:

```bash
cp .env.example .env
```

Variables requeridas:

```dotenv
# Firebase Android
FIREBASE_API_KEY_ANDROID=
FIREBASE_APP_ID_ANDROID=

# Firebase iOS
FIREBASE_API_KEY_IOS=
FIREBASE_APP_ID_IOS=
FIREBASE_IOS_CLIENT_ID=
FIREBASE_IOS_BUNDLE_ID=

# Firebase compartido
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=

# Google Sign In (dejar vacio para uso mobile directo)
GOOGLE_ANDROID_CLIENT_ID=
```

### 3. Configurar Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Agrega una app Android con el package `com.bsc.musplay`
3. Registra el SHA-1 de tu keystore de debug:

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

4. Descarga `google-services.json` y colócalo en `android/app/`
5. Habilita en Firebase: Authentication, Firestore y Storage

### 4. Instalar dependencias

```bash
flutter pub get
```

### 5. Correr la app

```bash
flutter run
```

---

## Correr en dispositivo fisico

```bash
# Listar dispositivos conectados
flutter devices

# Correr en un dispositivo especifico
flutter run -d <DEVICE_ID>
```

Asegurate de tener activada la **Depuracion USB** en las opciones de desarrollador del telefono.

---

## Generar APK

```bash
# Debug (para pruebas)
flutter build apk --debug

# Release (requiere keystore configurado)
flutter build apk --release
```

El APK de debug queda en:
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## Arquitectura

La app sigue una arquitectura por features con separacion de responsabilidades:

- **Presentation**: Widgets y pantallas (UI)
- **Domain**: Modelos de datos
- **Services**: Logica de negocio e integracion con APIs externas
- **Providers**: Manejo de estado con Provider

El audio corre en un `BaseAudioHandler` independiente del ciclo de vida de la UI, lo que permite reproduccion en segundo plano y control desde la notificacion del sistema.

Google Drive se maneja mediante `GoogleDriveService`, que autentica al usuario con `google_sign_in`, obtiene o crea una carpeta `MusPlayFiles` en su Drive y lista, sube o descarga archivos de audio desde esa carpeta.

---

## Nota sobre IA en el desarrollo

El 80% del codigo fue escrito con asistencia de Claude, GitHub Copilot y Gemini. El criterio de arquitectura, las decisiones de diseno y la integracion final fueron responsabilidad del desarrollador.

---

## Licencia

MIT
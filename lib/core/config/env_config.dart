import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static late DotEnv _dotenv;

  static Future<void> load() async {
    _dotenv = DotEnv();
    await _dotenv.load(fileName: '.env');
  }

  static String get(String key, {String defaultValue = ''}) {
    return _dotenv.env[key] ?? defaultValue;
  }

  // Firebase Android
  static String get firebaseApiKeyAndroid =>
      get('FIREBASE_API_KEY_ANDROID', defaultValue: 'YOUR_ANDROID_API_KEY');
  static String get firebaseAppIdAndroid =>
      get('FIREBASE_APP_ID_ANDROID', defaultValue: 'YOUR_ANDROID_APP_ID');

  // Firebase iOS
  static String get firebaseApiKeyIos =>
      get('FIREBASE_API_KEY_IOS', defaultValue: 'YOUR_IOS_API_KEY');
  static String get firebaseAppIdIos =>
      get('FIREBASE_APP_ID_IOS', defaultValue: 'YOUR_IOS_APP_ID');
  static String get firebaseIosClientId =>
      get('FIREBASE_IOS_CLIENT_ID', defaultValue: 'YOUR_IOS_CLIENT_ID');
  static String get firebaseIosBundleId =>
      get('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.example.musplay');

  // Firebase Web
  static String get firebaseApiKeyWeb =>
      get('FIREBASE_API_KEY_WEB', defaultValue: 'YOUR_WEB_API_KEY');
  static String get firebaseAppIdWeb =>
      get('FIREBASE_APP_ID_WEB', defaultValue: 'YOUR_WEB_APP_ID');
  static String get firebaseAuthDomain =>
      get('FIREBASE_AUTH_DOMAIN', defaultValue: 'YOUR_AUTH_DOMAIN');
  static String get firebaseMeasurementIdWeb =>
      get('FIREBASE_MEASUREMENT_ID_WEB', defaultValue: 'YOUR_MEASUREMENT_ID');

  // Firebase Windows
  static String get firebaseApiKeyWindows =>
      get('FIREBASE_API_KEY_WINDOWS', defaultValue: 'YOUR_WINDOWS_API_KEY');
  static String get firebaseAppIdWindows =>
      get('FIREBASE_APP_ID_WINDOWS', defaultValue: 'YOUR_WINDOWS_APP_ID');
  static String get firebaseMeasurementIdWindows =>
      get('FIREBASE_MEASUREMENT_ID_WINDOWS',
          defaultValue: 'YOUR_MEASUREMENT_ID');

  // Firebase macOS
  static String get firebaseApiKeyMacos =>
      get('FIREBASE_API_KEY_MACOS', defaultValue: 'YOUR_MACOS_API_KEY');
  static String get firebaseAppIdMacos =>
      get('FIREBASE_APP_ID_MACOS', defaultValue: 'YOUR_MACOS_APP_ID');

  // Shared Firebase
  static String get firebaseMessagingSenderId =>
      get('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '918279014967');
  static String get firebaseProjectId =>
      get('FIREBASE_PROJECT_ID', defaultValue: 'musplay-fe786');
  static String get firebaseStorageBucket => get('FIREBASE_STORAGE_BUCKET',
      defaultValue: 'musplay-fe786.firebasestorage.app');

  // Google Sign In - Android Client ID (necesario para Android)
  static String get googleAndroidClientId =>
      get('GOOGLE_ANDROID_CLIENT_ID', defaultValue: 'YOUR_GOOGLE_ANDROID_CLIENT_ID');
}

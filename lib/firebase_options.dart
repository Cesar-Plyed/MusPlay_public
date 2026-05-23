import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/config/env_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isAndroid) {
      return android;
    }
    if (Platform.isIOS) {
      return ios;
    }
    if (Platform.isMacOS) {
      return macos;
    }
    if (Platform.isWindows) {
      return windows;
    }
    if (Platform.isLinux) {
      return linux;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: EnvConfig.firebaseApiKeyAndroid,
        appId: EnvConfig.firebaseAppIdAndroid,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        storageBucket: EnvConfig.firebaseStorageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: EnvConfig.firebaseApiKeyIos,
        appId: EnvConfig.firebaseAppIdIos,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        storageBucket: EnvConfig.firebaseStorageBucket,
        iosClientId: EnvConfig.firebaseIosClientId,
        iosBundleId: EnvConfig.firebaseIosBundleId,
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: EnvConfig.firebaseApiKeyWeb,
        appId: EnvConfig.firebaseAppIdWeb,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        authDomain: EnvConfig.firebaseAuthDomain,
        storageBucket: EnvConfig.firebaseStorageBucket,
        measurementId: EnvConfig.firebaseMeasurementIdWeb,
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: EnvConfig.firebaseApiKeyMacos,
        appId: EnvConfig.firebaseAppIdMacos,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        storageBucket: EnvConfig.firebaseStorageBucket,
        iosClientId: EnvConfig.firebaseIosClientId,
        iosBundleId: EnvConfig.firebaseIosBundleId,
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: EnvConfig.firebaseApiKeyWindows,
        appId: EnvConfig.firebaseAppIdWindows,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        authDomain: EnvConfig.firebaseAuthDomain,
        storageBucket: EnvConfig.firebaseStorageBucket,
        measurementId: EnvConfig.firebaseMeasurementIdWindows,
      );

  static FirebaseOptions get linux => FirebaseOptions(
        apiKey: EnvConfig.firebaseApiKeyAndroid,
        appId: EnvConfig.firebaseAppIdAndroid,
        messagingSenderId: EnvConfig.firebaseMessagingSenderId,
        projectId: EnvConfig.firebaseProjectId,
        storageBucket: EnvConfig.firebaseStorageBucket,
      );
}

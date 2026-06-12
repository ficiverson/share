// ignore_for_file: type=lint
// Archivo placeholder. Genera el real ejecutando:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Esto sustituirá este archivo por uno con las opciones reales de tu
// proyecto de Firebase (apiKey, appId, projectId, etc.) para cada
// plataforma (web, android, ios, ...).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de Firebase por plataforma. **Placeholder** — sustituir con las
/// generadas por `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma. '
          'Ejecuta `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApwhvfNFXZz7SqesohkzhjU9TB2frKop8',
    appId: '1:929339448529:web:7665b8a6472f39692239f0',
    messagingSenderId: '929339448529',
    projectId: 'share-9309c',
    authDomain: 'share-9309c.firebaseapp.com',
    storageBucket: 'share-9309c.firebasestorage.app',
    measurementId: 'G-EZ8573YYK0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUi4mqbNp2r82se78Q0N7_gTk5QPVpmtQ',
    appId: '1:929339448529:android:4c1825954a5039d22239f0',
    messagingSenderId: '929339448529',
    projectId: 'share-9309c',
    storageBucket: 'share-9309c.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCe3LNbXLGRNDkak3JRI9nlbp8AQJ9Slec',
    appId: '1:929339448529:ios:2c1ebef146f9a2fb2239f0',
    messagingSenderId: '929339448529',
    projectId: 'share-9309c',
    storageBucket: 'share-9309c.firebasestorage.app',
    iosBundleId: 'com.example.shareApp',
  );
}

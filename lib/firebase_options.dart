// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDS6toHuE5S6-umMSNlBDuTs29FncAmuKM',
    appId: '1:427409631738:web:cc0ec17a65ebfcd44b9c43',
    messagingSenderId: '427409631738',
    projectId: 'social-media-app-436b7',
    authDomain: 'social-media-app-436b7.firebaseapp.com',
    storageBucket: 'social-media-app-436b7.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMcw6jDBdoKvCC265Wdde0BQ2dU5CzRzs',
    appId: '1:427409631738:android:820c057ee0cdbe974b9c43',
    messagingSenderId: '427409631738',
    projectId: 'social-media-app-436b7',
    storageBucket: 'social-media-app-436b7.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDS6toHuE5S6-umMSNlBDuTs29FncAmuKM',
    appId: '1:427409631738:web:0c5196759a599b384b9c43',
    messagingSenderId: '427409631738',
    projectId: 'social-media-app-436b7',
    authDomain: 'social-media-app-436b7.firebaseapp.com',
    storageBucket: 'social-media-app-436b7.appspot.com',
  );
}

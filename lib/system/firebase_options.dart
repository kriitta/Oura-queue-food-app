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
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyAfjZpybNJsl-G93-AwBwIHPK-r1oAdLIQ',
    appId: '1:676367016014:web:ac8d6fb8e6eae7975e231f',
    messagingSenderId: '676367016014',
    projectId: 'oura-app123',
    authDomain: 'oura-app123.firebaseapp.com',
    storageBucket: 'oura-app123.firebasestorage.app',
    measurementId: 'G-93R23881W4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBEwkJOGsiuGqo1j9K8bvpEzYCKzMNVvNw',
    appId: '1:676367016014:android:1a3c6cc7011d33745e231f',
    messagingSenderId: '676367016014',
    projectId: 'oura-app123',
    storageBucket: 'oura-app123.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC2d6N8QjFBYV8eCtMPGCAe175JaaFU7yY',
    appId: '1:676367016014:ios:1526c365a4ecfd355e231f',
    messagingSenderId: '676367016014',
    projectId: 'oura-app123',
    storageBucket: 'oura-app123.firebasestorage.app',
    iosBundleId: 'com.example.projectFinal',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC2d6N8QjFBYV8eCtMPGCAe175JaaFU7yY',
    appId: '1:676367016014:ios:1526c365a4ecfd355e231f',
    messagingSenderId: '676367016014',
    projectId: 'oura-app123',
    storageBucket: 'oura-app123.firebasestorage.app',
    iosBundleId: 'com.example.projectFinal',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAfjZpybNJsl-G93-AwBwIHPK-r1oAdLIQ',
    appId: '1:676367016014:web:b496377e525362f65e231f',
    messagingSenderId: '676367016014',
    projectId: 'oura-app123',
    authDomain: 'oura-app123.firebaseapp.com',
    storageBucket: 'oura-app123.firebasestorage.app',
    measurementId: 'G-C7RJS1HJYB',
  );
}

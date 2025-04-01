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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBHlRent4NfSy3Ry5acWHIYB1_YeT4YNAs',
    appId: '1:439789822578:web:0cc9dfde131626d68358eb',
    messagingSenderId: '439789822578',
    projectId: 'brainless-44c20',
    authDomain: 'brainless-44c20.firebaseapp.com',
    storageBucket: 'brainless-44c20.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBHlRent4NfSy3Ry5acWHIYB1_YeT4YNAs',
    appId: '1:439789822578:android:0cc9dfde131626d68358eb',
    messagingSenderId: '439789822578',
    projectId: 'brainless-44c20',
    storageBucket: 'brainless-44c20.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBHlRent4NfSy3Ry5acWHIYB1_YeT4YNAs',
    appId: '1:439789822578:ios:0cc9dfde131626d68358eb',
    messagingSenderId: '439789822578',
    projectId: 'brainless-44c20',
    storageBucket: 'brainless-44c20.firebasestorage.app',
    iosBundleId: 'com.example.brainiacz',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBHlRent4NfSy3Ry5acWHIYB1_YeT4YNAs',
    appId: '1:439789822578:macos:0cc9dfde131626d68358eb',
    messagingSenderId: '439789822578',
    projectId: 'brainless-44c20',
    storageBucket: 'brainless-44c20.firebasestorage.app',
    iosBundleId: 'com.example.brainiacz',
  );
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBzVr3H4zpDnnLuFiZuE08BGF-21ex-cio',
    appId: '1:830736415859:web:de8d4bbf1db18f139f3e06',
    messagingSenderId: '830736415859',
    projectId: 'clean-madurai',
    authDomain: 'clean-madurai.firebaseapp.com',
    storageBucket: 'clean-madurai.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzVr3H4zpDnnLuFiZuE08BGF-21ex-cio',
    appId: '1:830736415859:android:3da30686e6b3a4379f3e06',
    messagingSenderId: '830736415859',
    projectId: 'clean-madurai',
    storageBucket: 'clean-madurai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzVr3H4zpDnnLuFiZuE08BGF-21ex-cio',
    appId: '1:830736415859:ios:placeholder',
    messagingSenderId: '830736415859',
    projectId: 'clean-madurai',
    storageBucket: 'clean-madurai.firebasestorage.app',
    iosBundleId: 'com.cleanmadurai.app',
  );
}

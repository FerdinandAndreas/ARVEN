import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDLSPy_5UzG2vh02ukIjYVMeYcyUN05ZcE',
    appId: '1:972221714891:web:020cf023b1ad0cf8cea64e',
    messagingSenderId: '972221714891',
    projectId: 'arven-iot',
    authDomain: 'arven-iot.firebaseapp.com',
    databaseURL: 'https://arven-iot-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'arven-iot.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDLSPy_5UzG2vh02ukIjYVMeYcyUN05ZcE',
    appId: '1:972221714891:android:020cf023b1ad0cf8cea64e',
    messagingSenderId: '972221714891',
    projectId: 'arven-iot',
    databaseURL: 'https://arven-iot-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'arven-iot.firebasestorage.app',
  );
}

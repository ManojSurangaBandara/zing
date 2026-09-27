// File generated for zing-6578d Firebase configuration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHU1r_DIXjdwlnyaBgChdlUm-ItmSFyFg',
    appId: '1:6472810807:android:0d7ac1db59eab9764e1ab2',
    messagingSenderId: '6472810807',
    projectId: 'zing-6578d',
    storageBucket: 'zing-6578d.firebasestorage.app',
  );
}

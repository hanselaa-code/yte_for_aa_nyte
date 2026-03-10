import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCEmO2nS4Tk-ZFtBsI42ccJEIlYOsGQXlg',
    appId: '1:740995128450:android:df71851b3ed761c57de89b',
    messagingSenderId: '740995128450',
    projectId: 'ytnyt-cbdae',
    storageBucket: 'ytnyt-cbdae.firebasestorage.app',
  );
}

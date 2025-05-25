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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAFWETZOFvckP_E4gmW49StyiZ5HCO_hag',
    appId: '1:433894488599:ios:ce58ac54a9cd0463f93a52',
    messagingSenderId: '433894488599',
    projectId: 'balaghny',
    storageBucket: 'balaghny.firebasestorage.app',
    iosBundleId: 'com.example.balaghnyv1',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyApjbaUZ6vM1w8V3aJ8CTN4IIz3iciivqo",
    authDomain: "balaghny.firebaseapp.com",
    projectId: "balaghny",
    storageBucket: "balaghny.firebasestorage.app",
    messagingSenderId: "433894488599",
    appId: "1:433894488599:web:344f161d95dadd24f93a52",
    measurementId: "G-LW8NS4G87P",
  );
}

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for windows - you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCl4f-KS1P_N1a34qO06IXsR933PfMwi3I',
    appId: '1:183569548741:android:5db1ac142be71819d677ac',
    messagingSenderId: '183569548741',
    projectId: 'project-techni',
    storageBucket: 'project-techni.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCl4f-KS1P_N1a34qO06IXsR933PfMwi3I',
    appId: '1:183569548741:web:5db1ac142be71819d677ac', // Updated with real ID
    messagingSenderId: '183569548741',
    projectId: 'project-techni',
    storageBucket: 'project-techni.firebasestorage.app',
    authDomain: 'project-techni.firebaseapp.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCl4f-KS1P_N1a34qO06IXsR933PfMwi3I',
    appId: '1:183569548741:ios:5db1ac142be71819d677ac', // Updated with real ID
    messagingSenderId: '183569548741',
    projectId: 'project-techni',
    storageBucket: 'project-techni.firebasestorage.app',
    iosBundleId: 'com.techni.worker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCl4f-KS1P_N1a34qO06IXsR933PfMwi3I',
    appId: '1:183569548741:macos:5db1ac142be71819d677ac', // Updated with real ID
    messagingSenderId: '183569548741',
    projectId: 'project-techni',
    storageBucket: 'project-techni.firebasestorage.app',
    iosBundleId: 'com.techni.worker',
  );
}
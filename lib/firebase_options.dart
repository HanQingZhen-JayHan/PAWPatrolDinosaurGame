import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration for Pup Dash.
///
/// Replace the placeholder values below with your actual Firebase project config.
/// Get these from: Firebase Console → Project Settings → Your apps → Web app config.
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBQ9oy6YF3dSU2Ej3p-Dx-_UrRa5K6zhe4",
    authDomain: "pupdash-e2a07.firebaseapp.com",
    databaseURL: "https://pupdash-e2a07-default-rtdb.firebaseio.com",
    projectId: "pupdash-e2a07",
    storageBucket: "pupdash-e2a07.firebasestorage.app",
    messagingSenderId: "1027527544489",
    appId: "1:1027527544489:web:0de76e418069117e1f23b8",
    measurementId: "G-BNCMJQJVZZ"
  );

  static FirebaseOptions get currentPlatform => web;
}

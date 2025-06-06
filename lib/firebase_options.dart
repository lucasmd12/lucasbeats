// File generated by Manus based on user-provided configuration.
// IMPORTANT: The appId for Android below is a placeholder. 
// It is strongly recommended to regenerate this file using `flutterfire configure` in your local environment
// after setting up your Firebase project correctly for Android.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase options for use with your Firebase apps.
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
      // If you need web support, configure it here or regenerate with FlutterFire.
      // Returning Android config as a placeholder for web for now.
      print("Warning: Using Android Firebase config for Web platform. Regenerate with 'flutterfire configure' for proper web support.");
      return android; 
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        // If iOS config is needed, it should be added here.
        // Returning Android as placeholder. User should regenerate.
        print("Warning: Using Android Firebase config for iOS platform. Regenerate with 'flutterfire configure' for proper iOS support.");
        return android; // Placeholder - Use iOS specific if available and correctly generated
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSsny4kKt7OpMFkbiq4bp6VzNKIM4ZLTs',
    // Usando o ID do aplicativo encontrado na configuração do Firebase
    appId: '1:870531430015:android:3d26638dbfba0846db14a', 
    messagingSenderId: '870531430015',
    projectId: 'federacaomad-dbec9',
    authDomain: 'federacaomad-dbec9.firebaseapp.com', // Added from user config
    databaseURL: 'https://federacaomad-dbec9-default-rtdb.firebaseio.com', // Added from user config
    storageBucket: 'federacaomad-dbec9.appspot.com', // Standard format
    // measurementId: 'G-635BL7G5RK', // Usually optional for native platforms in DefaultFirebaseOptions
  );

  // Add iOS options here if needed, after generating them with FlutterFire CLI
  // static const FirebaseOptions ios = FirebaseOptions(
  //   apiKey: '...', 
  //   appId: '...', 
  //   messagingSenderId: '...', 
  //   projectId: '...', 
  //   databaseURL: '...', 
  //   storageBucket: '...', 
  //   iosBundleId: '...',
  // );
}


import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static bool get isConfigured {
    try {
      final options = currentPlatform;
      return !_isPlaceholder(options.apiKey) &&
          !_isPlaceholder(options.appId) &&
          !_isPlaceholder(options.messagingSenderId) &&
          !_isPlaceholder(options.projectId) &&
          !_isPlaceholder(options.storageBucket ?? '');
    } on UnsupportedError {
      return false;
    }
  }

  static String get configurationHelpMessage {
    return 'Firebase is not configured for this project yet.\n\n'
        'Open lib/firebase_options.dart and replace the placeholder values, or run '
        '`flutterfire configure` for your Firebase project.\n\n'
        'Required for Android:\n'
        '- valid apiKey\n'
        '- valid appId\n'
        '- valid messagingSenderId\n'
        '- valid projectId\n'
        '- valid storageBucket';
  }

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
        return linux;
      default:
        throw UnsupportedError('This platform is not configured for Firebase.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFhArpcKGW7H47y2j-rivX9hiK9AztZQ4',
    appId: '1:219266157640:android:01729278c7ccff121f9c7d',
    messagingSenderId: '219266157640',
    projectId: 'ai-cach',
    storageBucket: 'ai-cach.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:000000000000:ios:replace-me',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-your-project-id',
    storageBucket: 'replace-with-your-project-id.appspot.com',
    iosBundleId: 'com.example.aiStudyCoach',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_MACOS_API_KEY',
    appId: '1:000000000000:ios:replace-me',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-your-project-id',
    storageBucket: 'replace-with-your-project-id.appspot.com',
    iosBundleId: 'com.example.aiStudyCoach',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: '1:000000000000:web:replace-me',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-your-project-id',
    authDomain: 'replace-with-your-project-id.firebaseapp.com',
    storageBucket: 'replace-with-your-project-id.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WINDOWS_API_KEY',
    appId: '1:000000000000:web:replace-me',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-your-project-id',
    authDomain: 'replace-with-your-project-id.firebaseapp.com',
    storageBucket: 'replace-with-your-project-id.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_WITH_LINUX_API_KEY',
    appId: '1:000000000000:web:replace-me',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-your-project-id',
    authDomain: 'replace-with-your-project-id.firebaseapp.com',
    storageBucket: 'replace-with-your-project-id.appspot.com',
  );

  static bool _isPlaceholder(String value) {
    if (value.isEmpty) {
      return true;
    }

    return value.contains('REPLACE_WITH') ||
        value.contains('replace-me') ||
        value.contains('replace-with-your-project-id') ||
        value == '000000000000';
  }
}

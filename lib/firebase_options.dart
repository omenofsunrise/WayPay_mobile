import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Настройки Firebase, вшитые в код.
///
/// На Android конфигурацию подставляет Gradle-плагин из google-services.json,
/// а на iOS её надо либо класть в бандл через Xcode, либо передавать явно.
/// Передаём явно: тогда сборка не зависит от того, добавлен ли
/// GoogleService-Info.plist в проект Xcode.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase для веба не настроен.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase не настроен для платформы $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB1Ga57syCptMu5uqTjummqtqNnkcj8Ozo',
    appId: '1:436453303070:android:535a868fc17c88ff77df0f',
    messagingSenderId: '436453303070',
    projectId: 'waypayclient',
    storageBucket: 'waypayclient.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBefhJVKQhQQorRxU-jeAKoDJHpmKmQCvE',
    appId: '1:436453303070:ios:2aa10222def54ddc77df0f',
    messagingSenderId: '436453303070',
    projectId: 'waypayclient',
    storageBucket: 'waypayclient.firebasestorage.app',
    iosBundleId: 'one.waypay.mobile',
  );
}

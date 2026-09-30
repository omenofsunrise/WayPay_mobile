import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Обработчик пуша, пришедшего когда приложение полностью закрыто.
/// Обязан быть функцией верхнего уровня: Flutter поднимает под него
/// отдельный изолят, и метод объекта туда передать нельзя.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Пуш в фоне: ${message.messageId}');
}

/// Пуш-уведомления: разрешение, токен устройства, входящие сообщения.
///
/// Токен FCM протухает сам по себе — при переустановке приложения, очистке
/// данных, иногда просто по решению Firebase. Поэтому его мало получить один
/// раз при входе: сервис отдаёт токен наружу и при старте, и при каждом
/// обновлении, а кто его отправит на сервер — решает вызывающий код.
class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  final _tokenController = StreamController<String>.broadcast();
  StreamSubscription<String>? _refreshSubscription;
  String? _token;

  /// Последний известный токен устройства. Null, если его ещё не выдали.
  String? get token => _token;

  /// Токен при каждом появлении и обновлении. Подписчик получает и текущий,
  /// если тот уже известен, — иначе первый токен легко пропустить.
  Stream<String> get tokenStream async* {
    final current = _token;
    if (current != null) yield current;
    yield* _tokenController.stream;
  }

  /// Входящие пуши, когда приложение открыто. Системное уведомление в этом
  /// случае Android не показывает — рисовать его должно само приложение.
  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  /// Пуш, по которому приложение открыли из свёрнутого состояния.
  Stream<RemoteMessage> get openedMessages => FirebaseMessaging.onMessageOpenedApp;

  Future<void> init() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    final settings = await _messaging.requestPermission();
    debugPrint('🔔 Разрешение на уведомления: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _captureToken();

    _refreshSubscription?.cancel();
    _refreshSubscription = _messaging.onTokenRefresh.listen(_publish);
  }

  Future<void> _captureToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _publish(token);
        return;
      }
      // На iOS токен FCM появляется только после APNs, и в первые секунды
      // после запуска его может ещё не быть. Это не ошибка: подписка
      // onTokenRefresh отдаст его, как только он выдастся.
      debugPrint('⏳ Токен FCM пока не выдан');
    } on FirebaseException catch (e) {
      debugPrint('⚠️ Не удалось получить токен FCM: ${e.code}');
    }
  }

  void _publish(String token) {
    if (_token == token) return;
    _token = token;
    debugPrint('📱 Токен устройства: $token');
    _tokenController.add(token);
  }

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    await _tokenController.close();
  }
}

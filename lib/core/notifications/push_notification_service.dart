import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:waypay_mobile/firebase_options.dart';

/// Обработчик пуша, пришедшего когда приложение полностью закрыто.
/// Обязан быть функцией верхнего уровня: Flutter поднимает под него
/// отдельный изолят, и метод объекта туда передать нельзя.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await _ensureFirebase();
  debugPrint('🔔 Пуш в фоне: ${message.messageId}');
}

/// Поднимает Firebase, если он ещё не поднят. Настройки передаются явно:
/// на iOS GoogleService-Info.plist не входит в бандл, и без них
/// initializeApp падает с core/not-initialized.
Future<void> _ensureFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Пуш-уведомления: разрешение, токен устройства, входящие сообщения.
///
/// Токен FCM протухает сам по себе — при переустановке приложения, очистке
/// данных, иногда просто по решению Firebase. Поэтому его мало получить один
/// раз при входе: сервис отдаёт токен наружу и при старте, и при каждом
/// обновлении, а кто его отправит на сервер — решает вызывающий код.
class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
    : _injectedMessaging = messaging;

  final FirebaseMessaging? _injectedMessaging;

  /// Обращаться к Firebase можно только после Firebase.initializeApp(), а он
  /// вызывается уже внутри init(). Поэтому ссылка берётся лениво: конструктор
  /// обязан оставаться безопасным, его дёргает контейнер зависимостей.
  FirebaseMessaging get _messaging =>
      _injectedMessaging ?? FirebaseMessaging.instance;

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
  Stream<RemoteMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  Future<void> init() async {
    await _ensureFirebase();
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    final settings = await _messaging.requestPermission();
    debugPrint('🔔 Разрешение на уведомления: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      // На переднем плане уведомление уже показывает общий WebSocket-баннер.
      // Иначе iOS рисует второе системное уведомление поверх него.
      alert: false,
      badge: true,
      sound: false,
    );

    // Не ждём здесь: на iOS токен APNs приходит через несколько секунд, а
    // запуск приложения задерживать нельзя. Токен опубликуется сам, когда
    // станет доступен.
    unawaited(_captureToken());

    _refreshSubscription?.cancel();
    _refreshSubscription = _messaging.onTokenRefresh.listen(_publish);
  }

  Future<void> _captureToken() async {
    try {
      if (_needsApns && await _awaitApnsToken() == null) {
        debugPrint('⏳ APNs не отдал токен, FCM недоступен');
        return;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        _publish(token);
        return;
      }
      debugPrint('⏳ Токен FCM пока не выдан');
    } on FirebaseException catch (e) {
      debugPrint('⚠️ Не удалось получить токен FCM: ${e.code}');
    }
  }

  bool get _needsApns =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Пока APNs не выдал свой токен, запрос токена FCM падает с
  /// apns-token-not-set. Регистрация занимает несколько секунд и события о
  /// готовности нет, поэтому опрашиваем с паузами.
  Future<String?> _awaitApnsToken({
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final apns = await _messaging.getAPNSToken();
      if (apns != null) return apns;
      await Future<void>.delayed(step);
    }
    return null;
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

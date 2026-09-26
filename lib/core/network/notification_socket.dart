import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/network/socket_notification_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Живые уведомления по WebSocket — то же, что делает веб в `useWebSocket.ts`.
///
/// Порядок: подключиться к `/ws`, сразу отправить `{"EmployeeId": id}`,
/// слушать сообщения. При обрыве — переподключение с растущей задержкой,
/// не больше пяти попыток, как в вебе. Вкладку там оживляет
/// `visibilitychange`; на телефоне аналог — возврат приложения из фона,
/// этим управляет тот, кто вызывает [reconnectNow].
class NotificationSocket {
  NotificationSocket({
    String? url,
    WebSocketChannel Function(Uri uri)? connector,
    this.maxReconnectAttempts = 5,
    this.reconnectDelay = const Duration(seconds: 1),
  }) : _url = url ?? ApiConfig.notificationsWsUrl,
       _connector = connector ?? WebSocketChannel.connect;

  final String _url;
  final WebSocketChannel Function(Uri uri) _connector;
  final int maxReconnectAttempts;
  final Duration reconnectDelay;

  final _messages = StreamController<SocketNotificationMessage>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _attempts = 0;
  int? _employeeId;
  bool _disposed = false;

  /// Поток входящих уведомлений.
  Stream<SocketNotificationMessage> get messages => _messages.stream;

  bool get isConnected => _channel != null;

  /// Подключиться под конкретным сотрудником. Повторный вызов с тем же id
  /// ничего не делает, с другим — переподключает.
  void connect(int employeeId) {
    if (_disposed) return;
    if (_employeeId == employeeId && _channel != null) return;

    _employeeId = employeeId;
    _attempts = 0;
    _open();
  }

  void _open() {
    if (_disposed || _employeeId == null) return;

    _cancelReconnect();
    _closeChannel();

    try {
      final channel = _connector(Uri.parse(_url));
      _channel = channel;

      // Рукопожатие: бэкенд ждёт его первым сообщением и привязывает
      // соединение к сотруднику. Без него уведомления не придут.
      channel.sink.add(jsonEncode(SocketAuthMessage(employeeId: _employeeId!).toJson()));

      _subscription = channel.stream.listen(
        _onData,
        onError: (Object error) {
          debugPrint('WebSocket уведомлений: ошибка — $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket уведомлений: соединение закрыто');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _attempts = 0;
    } catch (e) {
      debugPrint('WebSocket уведомлений: не удалось подключиться — $e');
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map<String, dynamic>) return;
      _messages.add(SocketNotificationMessage.fromJson(decoded));
    } catch (e) {
      debugPrint('WebSocket уведомлений: не разобрал сообщение — $e');
    }
  }

  void _scheduleReconnect() {
    _closeChannel();
    if (_disposed || _employeeId == null) return;

    if (_attempts >= maxReconnectAttempts) {
      debugPrint('WebSocket уведомлений: попытки переподключения исчерпаны');
      return;
    }

    _attempts++;
    // Та же выдержка, что в вебе: задержка удваивается с каждой попыткой.
    final delay = reconnectDelay * (1 << (_attempts - 1));
    _reconnectTimer = Timer(delay, _open);
  }

  /// Немедленно переподключиться — вызывать при возврате приложения из фона.
  void reconnectNow() {
    if (_disposed || _employeeId == null) return;
    if (_channel != null) return;
    _attempts = 0;
    _open();
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _closeChannel() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Отключиться и забыть сотрудника — при выходе из аккаунта.
  void disconnect() {
    _employeeId = null;
    _attempts = 0;
    _cancelReconnect();
    _closeChannel();
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _messages.close();
  }
}

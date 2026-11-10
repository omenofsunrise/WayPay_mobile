import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/notification_socket.dart';
import 'package:waypay_mobile/core/network/socket_notification_message.dart';
import 'package:waypay_mobile/core/notifications/notification_route_handler.dart';
import 'package:waypay_mobile/core/notifications/notification_sound.dart';
import 'package:waypay_mobile/core/notifications/push_notification_service.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/widgets/in_app_notification_banner.dart';
import 'package:waypay_mobile/features/notifications/data/data_source/notifications_data_source.dart';
import 'package:waypay_mobile/features/notifications/data/models/notification_model.dart';
import 'package:waypay_mobile/routes/app_router.dart';

/// Единый обработчик уведомлений приложения. Повторяет веб-обработчик:
/// загружает непрочитанные при старте, принимает новые по `/ws`, держит до
/// пяти карточек и отмечает уведомление прочитанным при открытии или закрытии.
class LiveNotifications extends StatefulWidget {
  const LiveNotifications({super.key, required this.child});

  final Widget child;

  @override
  State<LiveNotifications> createState() => _LiveNotificationsState();
}

class _LiveNotificationsState extends State<LiveNotifications> {
  StreamSubscription<SocketNotificationMessage>? _socketSubscription;
  StreamSubscription<RemoteMessage>? _pushOpenSubscription;
  final _sound = NotificationSound();
  final _storage = UserStorage();
  final Set<String> _visibleSignatures = <String>{};

  NotificationsDataSource get _dataSource => getIt<NotificationsDataSource>();

  @override
  void initState() {
    super.initState();
    _socketSubscription = getIt<NotificationSocket>().messages.listen(
      _onSocketNotification,
    );
    final push = getIt<PushNotificationService>();
    _pushOpenSubscription = push.openedMessages.listen(_onPushOpened);
    _storage.notificationsEnabledNotifier.addListener(_onPreferencesChanged);
    _storage.showCreditNotificationsNotifier.addListener(_onPreferencesChanged);
    _storage.showWhatsAppNotificationsNotifier.addListener(
      _onPreferencesChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialUnread();
      _handleInitialPush(push);
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _pushOpenSubscription?.cancel();
    _storage.notificationsEnabledNotifier.removeListener(_onPreferencesChanged);
    _storage.showCreditNotificationsNotifier.removeListener(
      _onPreferencesChanged,
    );
    _storage.showWhatsAppNotificationsNotifier.removeListener(
      _onPreferencesChanged,
    );
    hideAllInAppNotifications();
    _sound.dispose();
    super.dispose();
  }

  void _onPreferencesChanged() {
    // Уже показанные карточки могли перестать проходить новый фильтр.
    // Очистка повторяет немедленное скрытие NotificationHandler на сайте.
    hideAllInAppNotifications();
    _visibleSignatures.clear();
  }

  Future<void> _loadInitialUnread() async {
    if (!_storage.notificationsEnabled) return;
    try {
      final page = await _dataSource.fetchNotifications(page: 1, pageSize: 10);
      if (!mounted) return;
      final unread = page.items
          .where((item) => !item.isRead)
          .where((item) => _storage.shouldShowNotificationType(item.type ?? ''))
          .take(5)
          .toList();
      for (final item in unread.reversed) {
        _show(_fromModel(item), knownId: item.id, playSound: false);
      }
    } catch (error) {
      debugPrint('Не удалось загрузить непрочитанные уведомления: $error');
    }
  }

  void _onSocketNotification(SocketNotificationMessage message) {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    if (!_storage.shouldShowNotificationType(message.type)) return;
    _show(message, playSound: true);
  }

  void _show(
    SocketNotificationMessage message, {
    int? knownId,
    required bool playSound,
  }) {
    if (message.title.trim().isEmpty && message.body.trim().isEmpty) return;
    final signature = _signature(message);
    if (!_visibleSignatures.add(signature)) return;

    final overlay = AppRouter.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    if (playSound) _sound.play();
    showInAppNotification(
      overlay,
      title: message.title,
      body: message.body,
      type: message.type,
      image: message.image,
      timestamp: message.timestamp,
      onTap: () async {
        _visibleSignatures.remove(signature);
        await _markAsRead(message, knownId: knownId);
        await NotificationRouteHandler.open(message.route);
      },
      onClose: () async {
        _visibleSignatures.remove(signature);
        await _markAsRead(message, knownId: knownId);
      },
    );
  }

  Future<void> _markAsRead(
    SocketNotificationMessage message, {
    int? knownId,
  }) async {
    try {
      final id = knownId ?? await _findNotificationId(message);
      if (id != null) await _dataSource.markAsRead(id);
    } catch (error) {
      debugPrint('Не удалось отметить уведомление прочитанным: $error');
    }
  }

  Future<int?> _findNotificationId(SocketNotificationMessage message) async {
    // Бэкенд отправляет WebSocket до сохранения записи. Небольшие повторы
    // устраняют гонку и дают получить настоящий id вместо временного.
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      final page = await _dataSource.fetchNotifications(page: 1, pageSize: 10);
      for (final item in page.items) {
        if (!item.isRead &&
            item.title == message.title &&
            item.message == message.body) {
          return item.id;
        }
      }
    }
    return null;
  }

  Future<void> _handleInitialPush(PushNotificationService push) async {
    final message = await push.getInitialMessage();
    if (message != null) await _onPushOpened(message);
  }

  Future<void> _onPushOpened(RemoteMessage message) async {
    await NotificationRouteHandler.open(message.data['route']);
  }

  SocketNotificationMessage _fromModel(NotificationModel item) {
    return SocketNotificationMessage(
      type: item.type ?? 'notification',
      title: item.title ?? '',
      body: item.message ?? '',
      image: item.senderAvatarPath,
      route: item.route,
      timestamp: item.dateTime,
    );
  }

  String _signature(SocketNotificationMessage message) =>
      '${message.type}\u0000${message.title}\u0000${message.body}';

  @override
  Widget build(BuildContext context) => widget.child;
}

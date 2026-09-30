import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/notification_socket.dart';
import 'package:waypay_mobile/core/network/socket_notification_message.dart';
import 'package:waypay_mobile/core/notifications/notification_sound.dart';
import 'package:waypay_mobile/core/widgets/in_app_notification_banner.dart';
import 'package:waypay_mobile/routes/app_router.dart';

/// Показывает уведомления, приходящие по WebSocket, поверх любого экрана —
/// как тост в вебе (`NotificationHandler.tsx`).
///
/// Живёт в корне приложения, потому что уведомление должно всплывать где
/// угодно, а не только там, где нарисован колокольчик.
class LiveNotifications extends StatefulWidget {
  const LiveNotifications({super.key, required this.child});

  final Widget child;

  @override
  State<LiveNotifications> createState() => _LiveNotificationsState();
}

class _LiveNotificationsState extends State<LiveNotifications> {
  StreamSubscription<SocketNotificationMessage>? _subscription;
  final _sound = NotificationSound();

  @override
  void initState() {
    super.initState();
    _subscription = getIt<NotificationSocket>().messages.listen(_onNotification);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _sound.dispose();
    super.dispose();
  }

  void _onNotification(SocketNotificationMessage message) {
    // Свёрнутое приложение озвучивает и показывает уведомление системой, по
    // самому пушу. Состояние может быть ещё не выставлено — это не повод
    // молчать, поэтому пустое значение считаем рабочим.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      debugPrint('Всплывашка пропущена: приложение не на переднем плане');
      return;
    }

    if (message.title.trim().isEmpty && message.body.trim().isEmpty) return;

    // Слой берём у навигатора напрямую. Поиск по контексту здесь не работает:
    // слой лежит ниже навигатора, а поиск идёт вверх.
    final overlay = AppRouter.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('Всплывашка пропущена: слой навигатора недоступен');
      return;
    }

    _sound.play();
    showInAppNotification(overlay, title: message.title, body: message.body);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

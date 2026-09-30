import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/notification_socket.dart';
import 'package:waypay_mobile/core/network/socket_notification_message.dart';
import 'package:waypay_mobile/core/notifications/notification_sound.dart';
import 'package:waypay_mobile/routes/app_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

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
    // самому пушу. Если сработать и здесь, человек получит два сигнала подряд
    // и всплывашку, которая вынырнет только при возврате в приложение.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final text = message.title.isEmpty
        ? message.body
        : '${message.title}: ${message.body}';
    if (text.trim().isEmpty) return;

    _sound.play();

    // Свой контекст не подходит: он выше Navigator, и Overlay над ним нет —
    // showAppMessage молча ничего не сделал бы. Берём контекст навигатора.
    final navigatorContext = AppRouter.navigatorKey.currentContext;
    if (navigatorContext == null) return;

    showAppMessage(
      navigatorContext,
      text,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

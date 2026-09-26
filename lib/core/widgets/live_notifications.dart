import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/notification_socket.dart';
import 'package:waypay_mobile/core/network/socket_notification_message.dart';
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

  @override
  void initState() {
    super.initState();
    _subscription = getIt<NotificationSocket>().messages.listen(_onNotification);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onNotification(SocketNotificationMessage message) {
    final text = message.title.isEmpty
        ? message.body
        : '${message.title}: ${message.body}';
    if (text.trim().isEmpty) return;

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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/notification_socket.dart';
import 'package:waypay_mobile/core/network/socket_notification_message.dart';
import 'package:waypay_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:waypay_mobile/features/notifications/presentation/widgets/notifications_sheet.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class NotificationsBellButton extends StatelessWidget {
  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final bool showBadge;

  const NotificationsBellButton({
    super.key,
    this.iconSize = 24,
    this.iconColor,
    this.badgeColor,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationsCubit>()..load(),
      child: _LiveNotifications(
        child: _NotificationsBellButtonBody(
          iconSize: iconSize,
          iconColor: iconColor,
          badgeColor: badgeColor,
          showBadge: showBadge,
        ),
      ),
    );
  }
}

class _NotificationsBellButtonBody extends StatelessWidget {
  const _NotificationsBellButtonBody({
    required this.iconSize,
    required this.iconColor,
    required this.badgeColor,
    required this.showBadge,
  });

  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unread = state.unreadCount;
        final badgeVisible = showBadge && unread > 0;
        final badgeText = unread > 99 ? '99+' : '$unread';
        final hitSize = iconSize < 44 ? 44.0 : iconSize;
        final iconTint = iconColor ?? const Color(AppColors.uiBorder);
        final bubbleColor = badgeColor ?? const Color(AppColors.primaryLight);

        return SizedBox(
          width: hitSize,
          height: hitSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => NotificationsSheet.show(context),
                  child: Center(
                    child: SvgPicture.asset(
                      SvgIcons.bell,
                      width: iconSize,
                      height: iconSize,
                      colorFilter: ColorFilter.mode(iconTint, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              if (badgeVisible)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(AppColors.white),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: AppStyle.manrope(
                        size: 10,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.black),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Слушает WebSocket уведомлений: обновляет счётчик колокольчика и показывает
/// сообщение поверх экрана — то же поведение, что у тоста в вебе.
class _LiveNotifications extends StatefulWidget {
  const _LiveNotifications({required this.child});

  final Widget child;

  @override
  State<_LiveNotifications> createState() => _LiveNotificationsState();
}

class _LiveNotificationsState extends State<_LiveNotifications> {
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
    if (!mounted) return;

    context.read<NotificationsCubit>().load(refresh: true);

    final text = message.title.isEmpty
        ? message.body
        : '${message.title}: ${message.body}';
    if (text.trim().isEmpty) return;

    showAppMessage(context, text, duration: const Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

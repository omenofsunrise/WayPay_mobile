import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/notifications/notification_presentation.dart';

OverlayEntry? _entry;
OverlayState? _overlay;
final List<_ActiveNotification> _notifications = [];
var _nextId = 0;

int showInAppNotification(
  OverlayState overlay, {
  required String title,
  required String body,
  String? type,
  String? image,
  DateTime? timestamp,
  FutureOr<void> Function()? onTap,
  FutureOr<void> Function()? onClose,
}) {
  _overlay = overlay;
  final id = ++_nextId;
  _notifications.insert(
    0,
    _ActiveNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      image: image,
      timestamp: timestamp ?? DateTime.now(),
      onTap: onTap,
      onClose: onClose,
    ),
  );
  if (_notifications.length > 5) {
    _notifications.removeRange(5, _notifications.length);
  }
  _render();
  return id;
}

void hideInAppNotification(int id) {
  _notifications.removeWhere((item) => item.id == id);
  _render();
}

void hideAllInAppNotifications() {
  _notifications.clear();
  _render();
}

void _render() {
  if (_notifications.isEmpty) {
    _entry?.remove();
    _entry = null;
    return;
  }
  if (_entry == null) {
    final overlay = _overlay;
    if (overlay == null) return;
    _entry = OverlayEntry(builder: (_) => const _NotificationStack());
    overlay.insert(_entry!);
  } else {
    _entry!.markNeedsBuild();
  }
}

class _ActiveNotification {
  const _ActiveNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.image,
    required this.timestamp,
    required this.onTap,
    required this.onClose,
  });

  final int id;
  final String title;
  final String body;
  final String? type;
  final String? image;
  final DateTime timestamp;
  final FutureOr<void> Function()? onTap;
  final FutureOr<void> Function()? onClose;
}

class _NotificationStack extends StatelessWidget {
  const _NotificationStack();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.paddingOf(context).top + 10,
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final notification in _notifications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NotificationBanner(notification: notification),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({required this.notification});

  final _ActiveNotification notification;

  @override
  Widget build(BuildContext context) {
    final title = notificationDisplayTitle(
      notification.title,
      notification.type,
    );
    final isCampaign = isAdminWhatsAppNotification(notification.type);

    return Material(
      key: ValueKey('notification-banner-${notification.id}'),
      color: const Color(AppColors.white),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          hideInAppNotification(notification.id);
          unawaited(Future.sync(() => notification.onTap?.call()));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCampaign
                  ? const Color(0xFF7C3AED)
                  : const Color(AppColors.greyLight),
              width: isCampaign ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationLeading(
                title: title,
                type: notification.type,
                image: notification.image,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCampaign) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1F7C3AED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '📣 Ответ на рекламу',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      title,
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.black),
                      ),
                    ),
                    if (notification.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      NotificationLinkText(
                        notification.body,
                        style: AppStyle.manrope(
                          size: 13,
                          weight: FontWeight.w500,
                          color: const Color(AppColors.grey),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatNotificationRelativeTime(notification.timestamp),
                    style: AppStyle.manrope(
                      size: 10,
                      weight: FontWeight.w400,
                      color: const Color(AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      hideInAppNotification(notification.id);
                      unawaited(
                        Future.sync(() => notification.onClose?.call()),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(
                        Icons.close,
                        color: Color(AppColors.grey),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

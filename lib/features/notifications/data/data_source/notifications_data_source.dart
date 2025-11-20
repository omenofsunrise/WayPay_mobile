import 'package:waypay_mobile/features/notifications/data/models/notification_page.dart';

abstract class NotificationsDataSource {
  Future<NotificationPage> fetchNotifications({int page = 1, int pageSize = 8});
  Future<void> markAsRead(int id);
}

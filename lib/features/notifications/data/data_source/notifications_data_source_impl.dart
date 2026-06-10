import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/notifications/data/data_source/notifications_data_source.dart';
import 'package:waypay_mobile/features/notifications/data/models/notification_page.dart';

class NotificationsDataSourceImpl implements NotificationsDataSource {
  NotificationsDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<NotificationPage> fetchNotifications({
    int page = 1,
    int pageSize = 8,
  }) async {
    try {
      final response = await _dio.get(
        'Notification/my',
        queryParameters: {'Page': page, 'PageSize': pageSize},
        options: Options(headers: {'accept': 'text/plain'}),
      );
      if (response.data is Map<String, dynamic>) {
        final pageData =
            NotificationPage.fromJson(response.data as Map<String, dynamic>);
        final unreadOnPage =
            pageData.items.where((item) => !item.isRead).length;
        final ids = pageData.items.map((e) => '#${e.id}-${e.isRead ? 'read' : 'unread'}').join(', ');
        // ignore: avoid_print
        print(
          '🔔 Notifications page=$page fetched ${pageData.items.length} items '
          '(unread on page: $unreadOnPage) -> [$ids]',
        );
        return pageData;
      }
      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить уведомления.');
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    try {
      await _dio.patch('Notification/read/$id');
      // ignore: avoid_print
      print('📨 Notification $id помечено как прочитанное');
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось обновить статус уведомления.',
      );
    }
  }
}

import 'package:dio/dio.dart';
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
        '/api/Notification/my',
        queryParameters: {'Page': page, 'PageSize': pageSize},
        options: Options(headers: {'accept': 'text/plain'}),
      );
      if (response.data is Map<String, dynamic>) {
        return NotificationPage.fromJson(response.data as Map<String, dynamic>);
      }
      throw const FormatException('Некорректный формат ответа');
    } on DioException catch (e) {
      final details = e.response?.data;
      throw Exception(
        'Не удалось получить уведомления: ${e.message} | $details',
      );
    }
  }
}

import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/get_schedule_query.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';

class ScheduleRemoteDataSourcesImpl implements ScheduleRemoteDataSources {
  final Dio dio;

  ScheduleRemoteDataSourcesImpl(this.dio);

  @override
  Future<ScheduleResponseModel> getSchedule(GetScheduleQuery query) async {
    try {
      final response = await dio.get(
        'Schedule',
        queryParameters: query.toQueryParams(),
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return ScheduleResponseModel.fromJson(data);
      } else {
        throw Exception('Неверный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка при получении ожидаемых платежей: ${e.message}');
    }
  }

  @override
  Future<ScheduleResponseModel> getScheduleByCredit({
    required int creditId,
    int page = 1,
    int pageSize = 3,
    bool includePayed = true,
  }) async {
    try {
      final response = await dio.get(
        'Schedule/by-credit/$creditId',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          'includePayed': includePayed,
        },
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return ScheduleResponseModel.fromJson(data);
      } else {
        throw Exception('Неверный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при получении ожидаемых платежей по договору: ${e.message}',
      );
    }
  }

  @override
  Future<void> putSchedule(int id) async {
    try {
      await dio.put('Schedule/$id');
    } on DioException catch (e) {
      throw Exception('Ошибка обновления статуса уведомления: ${e.message}');
    }
  }
}

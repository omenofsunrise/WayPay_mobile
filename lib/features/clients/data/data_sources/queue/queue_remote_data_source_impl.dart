import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/queue/queue_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/queue/get_queue_query_model.dart';
import 'package:waypay_mobile/features/clients/data/models/queue/queue_model.dart';
import 'package:waypay_mobile/features/clients/data/models/queue/queue_request_model.dart';

class QueueRemoteDataSourceImpl implements QueueRemoteDataSource {
  final Dio dio;

  QueueRemoteDataSourceImpl(this.dio);

  @override
  Future<QueueResponseModel> getQueue(GetQueueQuery query) async {
    try {
      final response = await dio.get(
        'Queue',
        queryParameters: query.toQueryParams(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return QueueResponseModel.fromJson(data);
      } else {
        throw Exception('Не тот формат');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения очереди: ${e.message}');
    }
  }

  @override
  Future<void> addQueueItem(QueueRequestModel request) async {
    try {
      await dio.post('Queue', data: request.toJson());
    } on DioException catch (e) {
      throw Exception('Ошибка добавления в очередь: ${e.message}');
    }
  }

  @override
  Future<QueueItemModel> getQueueById(int id) async {
    try {
      final response = await dio.get('Queue/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return QueueItemModel.fromJson(data);
      } else {
        throw Exception('Не тот формат');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения очереди по id: ${e.message}');
    }
  }

  @override
  Future<void> closeQueueById(int id) async {
    try {
      await dio.post('Queue/close/$id', data: {});
    } on DioException catch (e) {
      throw Exception('Ошибка закрытия очереди: ${e.message}');
    }
  }

  @override
  Future<void> deleteQueueById(int id) async {
    try {
      await dio.delete('Queue/$id');
    } on DioException catch (e) {
      throw Exception('Ошибка удаления очереди: ${e.message}');
    }
  }

  @override
  Future<void> updateQueueById(int id, QueueRequestModel request) async {
    try {
      await dio.put('Queue/$id', data: request.toJson());
    } on DioException catch (e) {
      throw Exception('Ошибка обновления очереди: ${e.message}');
    }
  }
}

import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/todo/data/data_soucres/task_remote_data_source.dart';
import 'package:waypay_mobile/features/todo/data/models/get_active_task_query.dart';
import 'package:waypay_mobile/features/todo/data/models/task_request.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final Dio dio;

  TaskRemoteDataSourceImpl(this.dio);

  @override
  Future<void> createTask(TaskRequest request) async {
    try {
      final response = await dio.post(
        'Task',
        data: request.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw const ApiError('Не удалось создать задачу.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать задачу.');
    }
  }

  @override
  Future<List<TodoTask>> fetchActiveTasks(GetActiveTasksQuery query) async {
    try {
      final response = await dio.get(
        'Task',
        queryParameters: query.toQueryParams(),
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => TodoTask.fromJson(json))
            .toList();
      } else {
        throw const ApiError('Не удалось загрузить задачи.');
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw mapApiError(e, fallback: 'Не удалось загрузить задачи.');
    }
  }

  @override
  Future<void> patchPendingTasks(int id) async {
    await _patchTaskStatus(id, 'pending');
  }

  @override
  Future<void> patchInProgressTasks(int id) async {
    await _patchTaskStatus(id, 'in-progress');
  }

  @override
  Future<void> patchReviewTasks(int id) async {
    await _patchTaskStatus(id, 'review');
  }

  @override
  Future<void> patchDoneTasks(int id) async {
    await _patchTaskStatus(id, 'done');
  }

  @override
  Future<void> deleteTask(int id) async {
    try {
      final response = await dio.delete('Task/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ApiError('Не удалось удалить задачу.');
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw mapApiError(e, fallback: 'Не удалось удалить задачу.');
    }
  }

  Future<void> _patchTaskStatus(int id, String status) async {
    try {
      final response = await dio.patch('Task/$id/$status');
      if (response.statusCode != 200) {
        throw const ApiError('Не удалось обновить статус задачи.');
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw mapApiError(e, fallback: 'Не удалось обновить статус задачи.');
    }
  }

  @override
  Future<void> updateTask(int id, TaskRequest request) async {
    try {
      final response = await dio.put(
        'Task/$id',
        data: request.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != 200) {
        throw const ApiError('Не удалось обновить задачу.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить задачу.');
    }
  }

  @override
  Future<int> getActiveCountTasks() async {
    try {
      final response = await dio.get('Task/active-count');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is int) {
          return data;
        } else if (data is String) {
          final parsed = int.tryParse(data);
          if (parsed != null) return parsed;
        }

        throw const ApiError('Сервер вернул некорректный ответ.');
      } else {
        throw const ApiError('Не удалось загрузить количество задач.');
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить количество активных задач.',
      );
    }
  }
}

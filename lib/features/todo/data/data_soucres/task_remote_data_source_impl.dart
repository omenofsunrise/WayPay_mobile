import 'package:dio/dio.dart';
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
        throw Exception('Ошибка при создании задачи: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка при создании задачи: ${e.message}');
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
        throw Exception('Ошибка получения задач: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка получения задач: $e');
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
        throw Exception('Ошибка при удалении задачи: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при удалении задачи $id: $e');
    }
  }

  Future<void> _patchTaskStatus(int id, String status) async {
    try {
      final response = await dio.patch('Task/$id/$status');
      if (response.statusCode != 200) {
        throw Exception('Ошибка PATCH запроса: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
        'Ошибка при обновлении статуса "$status" у задачи $id: $e',
      );
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
        throw Exception('Ошибка при обновлении задачи: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка при обновлении задачи: ${e.message}');
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

        throw Exception('Некорректный тип данных: ${data.runtimeType}');
      } else {
        throw Exception('Ошибка запроса: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении количества активных задач: $e');
    }
  }
}

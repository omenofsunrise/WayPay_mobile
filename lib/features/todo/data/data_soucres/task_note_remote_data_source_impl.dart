import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/todo/data/data_soucres/task_note_remote_data_source.dart';
import 'package:waypay_mobile/features/todo/data/models/task_note_model.dart';

class TaskNoteRemoteDataSourceImpl implements TaskNoteRemoteDataSource {
  final Dio dio;

  TaskNoteRemoteDataSourceImpl(this.dio);

  @override
  Future<List<TaskNote>> getTaskNotes(int taskId) async {
    try {
      final response = await dio.get('TaskNote/task/$taskId');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => TaskNote.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить комментарии.');
    }
  }

  @override
  Future<TaskNote> getTaskNote(int id) async {
    try {
      final response = await dio.get('TaskNote/$id');
      return TaskNote.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить комментарий.');
    }
  }

  @override
  Future<TaskNote> createTaskNote({
    required String text,
    required int taskId,
    required int createdBy,
  }) async {
    try {
      final response = await dio.post(
        'TaskNote',
        data: {'text': text, 'taskId': taskId, 'createdBy': createdBy},
      );
      return TaskNote.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать комментарий.');
    }
  }

  @override
  Future<TaskNote> updateTaskNote({
    required int id,
    required String text,
  }) async {
    try {
      final response = await dio.put('TaskNote/$id', data: {'text': text});
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TaskNote.fromJson(data);
      }
      return await getTaskNote(id);
    } catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить комментарий.');
    }
  }

  @override
  Future<void> deleteTaskNote(int id) async {
    try {
      await dio.delete('TaskNote/$id');
    } catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить комментарий.');
    }
  }
}

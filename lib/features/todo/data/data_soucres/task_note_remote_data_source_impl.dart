import 'package:dio/dio.dart';
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
      throw Exception('Ошибка загрузки комментариев: $e');
    }
  }

  @override
  Future<TaskNote> getTaskNote(int id) async {
    try {
      final response = await dio.get('TaskNote/$id');
      return TaskNote.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Ошибка загрузки комментария: $e');
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
      throw Exception('Ошибка создания комментария: $e');
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
      throw Exception('Ошибка обновления комментария: $e');
    }
  }

  @override
  Future<void> deleteTaskNote(int id) async {
    try {
      await dio.delete('TaskNote/$id');
    } catch (e) {
      throw Exception('Ошибка удаления комментария: $e');
    }
  }
}

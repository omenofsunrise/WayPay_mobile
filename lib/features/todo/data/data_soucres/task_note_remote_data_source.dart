import 'package:waypay_mobile/features/todo/data/models/task_note_model.dart';

abstract class TaskNoteRemoteDataSource {
  Future<List<TaskNote>> getTaskNotes(int taskId);
  Future<TaskNote> getTaskNote(int id);
  Future<TaskNote> createTaskNote({
    required String text,
    required int taskId,
    required int createdBy,
  });
  Future<TaskNote> updateTaskNote({required int id, required String text});
  Future<void> deleteTaskNote(int id);
}

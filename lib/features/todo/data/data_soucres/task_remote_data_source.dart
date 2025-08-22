import 'package:waypay/features/todo/data/models/get_active_task_query.dart';
import 'package:waypay/features/todo/data/models/task_request.dart';
import 'package:waypay/features/todo/data/models/todo_model.dart';

abstract class TaskRemoteDataSource {
  Future<void> createTask(TaskRequest request);
  Future<List<TodoTask>> fetchActiveTasks(GetActiveTasksQuery query);
  Future<void> patchPendingTasks(int id);
  Future<void> patchInProgressTasks(int id);
  Future<void> patchReviewTasks(int id);
  Future<void> patchDoneTasks(int id);
  Future<void> deleteTask(int id);
  Future<void> updateTask(int id, TaskRequest request);
  Future<int> getActiveCountTasks();
}

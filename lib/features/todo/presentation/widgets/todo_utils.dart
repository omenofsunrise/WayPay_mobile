import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';

Map<TaskStatus, List<TodoTask>> groupTasksByStatus(List<TodoTask> tasks) {
  final map = <TaskStatus, List<TodoTask>>{
    TaskStatus.pending: [],
    TaskStatus.inProgress: [],
    TaskStatus.review: [],
    TaskStatus.done: [],
  };
  for (final task in tasks) {
    map[task.taskStatus]?.add(task);
  }
  return map;
}

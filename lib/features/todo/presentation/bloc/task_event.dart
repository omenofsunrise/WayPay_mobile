part of 'task_bloc.dart';

abstract class TaskEvent {}

class LoadActiveTasks extends TaskEvent {
  final bool? onlyMine;
  final TaskPriority? priority;
  final int? taskEmployeeId;
  final TaskStatus? status;

  LoadActiveTasks({
    this.onlyMine,
    this.priority,
    this.taskEmployeeId,
    this.status,
  });
}

class CreateTask extends TaskEvent {
  final TaskRequest task;

  CreateTask(this.task);
}

class UpdateTaskStatus extends TaskEvent {
  final int taskId;
  final TaskStatus newStatus;
  UpdateTaskStatus({required this.taskId, required this.newStatus});
}

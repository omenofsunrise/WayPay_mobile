import 'package:waypay/features/todo/data/models/todo_model.dart';

class GetActiveTasksQuery {
  final bool onlyMine;
  final bool includeCompleted;
  final TaskPriority? priority;
  final int? taskEmployeeId;

  GetActiveTasksQuery({this.onlyMine = false, this.includeCompleted = true, this.priority, this.taskEmployeeId});

  Map<String, dynamic> toQueryParams() {
    return {
      'onlyMine': onlyMine,
      'includeCompleted': includeCompleted,
      if (priority != null && priority != TaskPriority.all) 'priority': priority!.name,
      if (taskEmployeeId != null) 'taskEmployeeId': taskEmployeeId,
    };
  }
}

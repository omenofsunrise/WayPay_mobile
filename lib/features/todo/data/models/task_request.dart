import 'package:waypay/features/todo/data/models/todo_model.dart';

class TaskRequest {
  final String? title;
  final int? employeeId;
  final int? responsibleId;
  final DateTime? deadline;
  final TaskPriority priority;

  TaskRequest({this.title, this.employeeId, this.responsibleId, this.deadline, required this.priority});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'employeeId': employeeId,
      'responsibleId': responsibleId,
      'deadline': deadline?.toIso8601String(),
      'priority': priority.name,
    };
  }

  factory TaskRequest.fromJson(Map<String, dynamic> json) {
    return TaskRequest(
      title: json['title'],
      employeeId: json['employeeId'],
      responsibleId: json['responsibleId'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      priority: TaskPriority.values.firstWhere((e) => e.name == json['priority']),
    );
  }
}

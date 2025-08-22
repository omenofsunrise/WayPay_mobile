enum TaskPriority { all, low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Низкий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.high:
        return 'Высокий';
      case TaskPriority.all:
        return 'Любой';
    }
  }
}

enum TaskStatus { pending, inProgress, done, review }

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'К выполнению';
      case TaskStatus.review:
        return 'На проверке';
      case TaskStatus.inProgress:
        return 'В работе';
      case TaskStatus.done:
        return 'Выполнено';
    }
  }
}

TaskStatus _parseTaskStatus(String raw) {
  switch (raw) {
    case 'pending':
      return TaskStatus.pending;
    case 'in_progress':
      return TaskStatus.inProgress;
    case 'review':
      return TaskStatus.review;
    case 'done':
      return TaskStatus.done;
    default:
      throw ArgumentError('Unknown TaskStatus: $raw');
  }
}

class TodoTask {
  final int id;
  final String title;
  final int? employeeId;
  final int? responsibleId;
  final int companyId;
  final int createdBy;
  final String? creatorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deadline;
  final DateTime? completedAt;
  final TaskStatus taskStatus;
  final TaskPriority priority;
  final String? employeeName;
  final String? responsibleName;
  final String? employeePhotoPath;

  TodoTask({
    required this.id,
    required this.title,
    this.employeeId,
    this.responsibleId,
    required this.companyId,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    this.deadline,
    this.completedAt,
    required this.taskStatus,
    required this.priority,
    this.employeeName,
    this.responsibleName,
    this.employeePhotoPath,
  });

  factory TodoTask.fromJson(Map<String, dynamic> json) {
    return TodoTask(
      id: json['id'] as int,
      title: json['title'] as String,
      employeeId: json['employeeId'] != null ? json['employeeId'] as int : null,
      responsibleId: json['responsibleId'] != null
          ? json['responsibleId'] as int
          : null,
      companyId: json['companyId'] as int,
      createdBy: json['createdBy'] as int,
      creatorName: json['creatorName'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      taskStatus: _parseTaskStatus(json['taskStatus']),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      employeeName: json['employeeFullName'] as String?,
      responsibleName: json['responsibleFullName'] as String?,
      employeePhotoPath: json['employeePhotoPath'] as String?,
    );
  }

  TodoTask copyWith({
    int? id,
    String? title,
    int? employeeId,
    int? responsibleId,
    int? companyId,
    int? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadline,
    DateTime? completedAt,
    TaskStatus? taskStatus,
    TaskPriority? priority,
    String? employeeName,
    String? responsibleName,
    String? employeePhotoPath,
  }) {
    return TodoTask(
      id: id ?? this.id,
      title: title ?? this.title,
      employeeId: employeeId ?? this.employeeId,
      responsibleId: responsibleId ?? this.responsibleId,
      companyId: companyId ?? this.companyId,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      taskStatus: taskStatus ?? this.taskStatus,
      priority: priority ?? this.priority,
      employeeName: employeeName ?? this.employeeName,
      responsibleName: responsibleName ?? this.responsibleName,
      employeePhotoPath: employeePhotoPath ?? this.employeePhotoPath,
    );
  }
}

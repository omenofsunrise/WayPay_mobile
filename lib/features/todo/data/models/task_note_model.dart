class TaskNoteUser {
  final int id;
  final String fullName;
  final String? photoPath;

  TaskNoteUser({
    required this.id,
    required this.fullName,
    this.photoPath,
  });

  factory TaskNoteUser.fromJson(Map<String, dynamic> json) {
    return TaskNoteUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
    );
  }
}

class TaskNote {
  final int id;
  final String text;
  final int taskId;
  final DateTime createdAt;
  final int createdBy;
  final TaskNoteUser? creator;

  TaskNote({
    required this.id,
    required this.text,
    required this.taskId,
    required this.createdAt,
    required this.createdBy,
    this.creator,
  });

  factory TaskNote.fromJson(Map<String, dynamic> json) {
    return TaskNote(
      id: (json['id'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      taskId: (json['taskId'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdBy: (json['createdBy'] as num?)?.toInt() ?? 0,
      creator: json['creator'] is Map<String, dynamic>
          ? TaskNoteUser.fromJson(
              json['creator'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

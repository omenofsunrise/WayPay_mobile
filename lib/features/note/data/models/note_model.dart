class NoteModel {
  final int id;
  final String content;
  final DateTime createdAt;
  final int employeeId;

  NoteModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.employeeId,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      employeeId: json['employeeId'],
    );
  }
}

class NoteModel {
  final int id;
  final String noteableType;
  final int noteableId;
  final int employeeId;
  final String content;
  final DateTime createdAt;
  final DateTime? remindDate;
  final String? employeeName;
  final String? employeeAvatar;
  final String? fileBase64;
  final String? fileName;

  NoteModel({
    required this.id,
    required this.noteableType,
    required this.noteableId,
    required this.employeeId,
    required this.content,
    required this.createdAt,
    this.remindDate,
    this.employeeName,
    this.employeeAvatar,
    this.fileBase64,
    this.fileName,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      noteableType: json['noteableType'],
      noteableId: json['noteableId'],
      employeeId: json['employeeId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      remindDate: json['remindDate'] == null
          ? null
          : DateTime.parse(json['remindDate']),
      employeeName: json['employeeName'],
      employeeAvatar: json['employeeAvatar'],
      fileBase64: json['fileBase64'],
      fileName: json['fileName'],
    );
  }
}

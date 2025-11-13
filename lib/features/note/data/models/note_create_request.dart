class NoteCreateRequest {
  final int noteableId;
  final String noteableType;
  final String content;
  final DateTime? remindDate;
  final String? file;

  NoteCreateRequest({
    required this.noteableId,
    this.noteableType = 'credit',
    required this.content,
    this.remindDate,
    this.file,
  });

  Map<String, dynamic> toJson() => {
    'noteableId': noteableId,
    'noteableType': noteableType,
    'content': content,
    if (remindDate != null) 'remindDate': remindDate!.toIso8601String(),
    if (file != null) 'file': file,
  };
}

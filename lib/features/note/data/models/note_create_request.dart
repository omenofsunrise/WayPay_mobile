class NoteCreateRequest {
  final int creditId;
  final String? content;

  NoteCreateRequest({required this.creditId, this.content});

  Map<String, dynamic> toJson() => {'creditId': creditId, 'content': content};
}

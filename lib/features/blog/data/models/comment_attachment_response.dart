class CommentAttachmentResponse {
  final int id;
  final String? filePath;
  final bool isImage;
  final String? fileName;

  CommentAttachmentResponse({
    required this.id,
    this.filePath,
    required this.isImage,
    this.fileName,
  });

  factory CommentAttachmentResponse.fromJson(Map<String, dynamic> json) {
    return CommentAttachmentResponse(
      id: json['id'] as int,
      filePath: json['filePath'] as String?,
      isImage: json['isImage'] as bool,
      fileName: json['fileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'isImage': isImage,
      'fileName': fileName,
    };
  }
}

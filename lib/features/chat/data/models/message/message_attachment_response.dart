class MessageAttachmentResponse {
  final int id;
  final int messageId;
  final String? fileName;
  final String? fileUrl;
  final int fileSize;
  final String? contentType;
  final DateTime sentAt;
  final int senderId;
  final String? senderName;

  const MessageAttachmentResponse({
    required this.id,
    required this.messageId,
    this.fileName,
    this.fileUrl,
    required this.fileSize,
    this.contentType,
    required this.sentAt,
    required this.senderId,
    this.senderName,
  });

  factory MessageAttachmentResponse.fromJson(Map<String, dynamic> json) =>
      MessageAttachmentResponse(
        id: (json['id'] as num).toInt(),
        messageId: (json['messageId'] as num).toInt(),
        fileName: json['fileName'] as String?,
        fileUrl: json['fileUrl'] as String?,
        fileSize: (json['fileSize'] as num).toInt(),
        contentType: json['contentType'] as String?,
        sentAt: DateTime.parse(json['sentAt'] as String),
        senderId: (json['senderId'] as num).toInt(),
        senderName: json['senderName'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'messageId': messageId,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'fileSize': fileSize,
    'contentType': contentType,
    'sentAt': sentAt.toUtc().toIso8601String(),
    'senderId': senderId,
    'senderName': senderName,
  };
}

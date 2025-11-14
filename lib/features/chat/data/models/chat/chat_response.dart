DateTime? _parseDate(String? s) => s == null ? null : DateTime.parse(s);
String? _dateToJson(DateTime? d) => d?.toUtc().toIso8601String();

class SimpleEmployeeDto {
  final int id;
  final String? fullName;
  final String? photoPath;

  const SimpleEmployeeDto({required this.id, this.fullName, this.photoPath});

  SimpleEmployeeDto copyWith({int? id, String? fullName, String? photoPath}) =>
      SimpleEmployeeDto(id: id ?? this.id, fullName: fullName ?? this.fullName, photoPath: photoPath ?? this.photoPath);

  factory SimpleEmployeeDto.fromJson(Map<String, dynamic> json) => SimpleEmployeeDto(
    id: (json['id'] as num).toInt(),
    fullName: json['fullName'] as String?,
    photoPath: json['photoPath'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'fullName': fullName, 'photoPath': photoPath};
}

class MessageAttachmentResponse {
  final int id;
  final int messageId;
  final String? fileName; // nullable
  final String? fileUrl; // nullable
  final int fileSize;
  final String? contentType; // nullable
  final DateTime sentAt; // обязательный
  final int? senderId; // nullable
  final String? senderName; // nullable

  const MessageAttachmentResponse({
    required this.id,
    required this.messageId,
    this.fileName,
    this.fileUrl,
    required this.fileSize,
    this.contentType,
    required this.sentAt,
    this.senderId,
    this.senderName,
  });

  MessageAttachmentResponse copyWith({
    int? id,
    int? messageId,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    String? contentType,
    DateTime? sentAt,
    int? senderId,
    String? senderName,
  }) => MessageAttachmentResponse(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    fileName: fileName ?? this.fileName,
    fileUrl: fileUrl ?? this.fileUrl,
    fileSize: fileSize ?? this.fileSize,
    contentType: contentType ?? this.contentType,
    sentAt: sentAt ?? this.sentAt,
    senderId: senderId ?? this.senderId,
    senderName: senderName ?? this.senderName,
  );

  factory MessageAttachmentResponse.fromJson(Map<String, dynamic> json) {
    // API иногда шлёт "0001-01-01T00:00:00", которое невалидно для UI → считаем как "сейчас"
    final rawSentAt = json['sentAt'] as String;
    late final DateTime parsedSentAt;
    try {
      parsedSentAt = DateTime.parse(rawSentAt);
    } catch (_) {
      parsedSentAt = DateTime.now(); // fallback
    }

    return MessageAttachmentResponse(
      id: (json['id'] as num).toInt(),
      messageId: (json['messageId'] as num).toInt(),
      fileName: json['fileName'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileSize: (json['fileSize'] as num).toInt(),
      contentType: json['contentType'] as String?,
      sentAt: parsedSentAt,
      senderId: (json['senderId'] as num?)?.toInt(),
      senderName: json['senderName'] as String?,
    );
  }

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

class MessageResponse {
  final int id;
  final String? text;
  final DateTime sentAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final int chatId;
  final int? postId;
  final SimpleEmployeeDto sender;
  final MessageResponse? replyTo;
  final List<MessageAttachmentResponse>? attachments;

  const MessageResponse({
    required this.id,
    this.text,
    required this.sentAt,
    this.updatedAt,
    required this.isDeleted,
    required this.chatId,
    this.postId,
    required this.sender,
    this.replyTo,
    this.attachments,
  });

  MessageResponse copyWith({
    int? id,
    String? text,
    DateTime? sentAt,
    DateTime? updatedAt,
    bool? isDeleted,
    int? chatId,
    int? postId,
    SimpleEmployeeDto? sender,
    MessageResponse? replyTo,
    List<MessageAttachmentResponse>? attachments,
  }) => MessageResponse(
    id: id ?? this.id,
    text: text ?? this.text,
    sentAt: sentAt ?? this.sentAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    chatId: chatId ?? this.chatId,
    postId: postId ?? this.postId,
    sender: sender ?? this.sender,
    replyTo: replyTo ?? this.replyTo,
    attachments: attachments ?? this.attachments,
  );

  factory MessageResponse.fromJson(Map<String, dynamic> json) => MessageResponse(
    id: (json['id'] as num).toInt(),
    text: json['text'] as String?,
    sentAt: DateTime.parse(json['sentAt'] as String),
    updatedAt: _parseDate(json['updatedAt'] as String?),
    isDeleted: json['isDeleted'] as bool? ?? false,
    chatId: (json['chatId'] as num).toInt(),
    postId: (json['postId'] as num?)?.toInt(),
    sender: SimpleEmployeeDto.fromJson(json['sender'] as Map<String, dynamic>),
    replyTo: (json['replyTo'] is Map && (json['replyTo'] as Map).isNotEmpty)
        ? MessageResponse.fromJson(json['replyTo'] as Map<String, dynamic>)
        : null,
    attachments: (json['attachments'] as List?)
        ?.map((e) => MessageAttachmentResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sentAt': sentAt.toUtc().toIso8601String(),
    'updatedAt': _dateToJson(updatedAt),
    'isDeleted': isDeleted,
    'chatId': chatId,
    'postId': postId,
    'sender': sender.toJson(),
    'replyTo': replyTo?.toJson(),
    'attachments': attachments?.map((e) => e.toJson()).toList(),
  };
}

class ChatResponse {
  final int id;
  final String? name;
  final String? type;
  final DateTime createdAt;
  final int unreadCount;
  final MessageResponse? lastMessage;
  final String? avatarPath;

  const ChatResponse({
    required this.id,
    this.name,
    this.type,
    required this.createdAt,
    required this.unreadCount,
    this.lastMessage,
    this.avatarPath,
  });

  ChatResponse copyWith({
    int? id,
    String? name,
    String? type,
    DateTime? createdAt,
    int? unreadCount,
    MessageResponse? lastMessage,
    String? avatarPath,
  }) => ChatResponse(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    unreadCount: unreadCount ?? this.unreadCount,
    lastMessage: lastMessage ?? this.lastMessage,
    avatarPath: avatarPath ?? this.avatarPath,
  );

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String?,
    type: json['type'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    unreadCount: (json['unreadCount'] as num).toInt(),
    lastMessage: json['lastMessage'] != null
        ? MessageResponse.fromJson(json['lastMessage'] as Map<String, dynamic>)
        : null,
    avatarPath: json['avatarPath'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'unreadCount': unreadCount,
    'lastMessage': lastMessage?.toJson(),
    'avatarPath': avatarPath,
  };
}

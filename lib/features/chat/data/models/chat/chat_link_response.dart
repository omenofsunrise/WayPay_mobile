String? _dateToJson(DateTime? d) => d?.toUtc().toIso8601String();

class ChatLinkResponse {
  final int messageId;
  final String? url;
  final DateTime sentAt;
  final int senderId;
  final String? senderName;

  const ChatLinkResponse({
    required this.messageId,
    this.url,
    required this.sentAt,
    required this.senderId,
    this.senderName,
  });

  ChatLinkResponse copyWith({
    int? messageId,
    String? url,
    DateTime? sentAt,
    int? senderId,
    String? senderName,
  }) => ChatLinkResponse(
    messageId: messageId ?? this.messageId,
    url: url ?? this.url,
    sentAt: sentAt ?? this.sentAt,
    senderId: senderId ?? this.senderId,
    senderName: senderName ?? this.senderName,
  );

  factory ChatLinkResponse.fromJson(Map<String, dynamic> json) =>
      ChatLinkResponse(
        messageId: (json['messageId'] as num).toInt(),
        url: json['url'] as String?,
        sentAt: DateTime.parse(json['sentAt'] as String),
        senderId: (json['senderId'] as num).toInt(),
        senderName: json['senderName'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'url': url,
    'sentAt': _dateToJson(sentAt),
    'senderId': senderId,
    'senderName': senderName,
  };
}

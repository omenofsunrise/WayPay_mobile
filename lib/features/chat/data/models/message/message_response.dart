import 'package:equatable/equatable.dart';
import 'package:waypay/features/chat/data/models/chat/chat_response.dart';

DateTime? _parseDate(String? s) => s == null ? null : DateTime.parse(s);
String? _dateToJson(DateTime? d) => d?.toUtc().toIso8601String();

class MessageResponse extends Equatable {
  final int id;
  final String? text;
  final DateTime sentAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final int chatId;
  final int? postId;
  final SimpleEmployeeDto? sender; // nullable
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
    this.sender,
    this.replyTo,
    this.attachments,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      MessageResponse(
        id: (json['id'] as num).toInt(),
        text: json['text'] as String?,
        sentAt: DateTime.parse(json['sentAt'] as String),
        updatedAt: _parseDate(json['updatedAt'] as String?),
        isDeleted: json['isDeleted'] as bool? ?? false,
        chatId: (json['chatId'] as num).toInt(),
        postId: (json['postId'] as num?)?.toInt(),

        // --- БЕЗОПАСНО! sender может быть null или не Map ---
        sender: (json['sender'] is Map<String, dynamic>)
            ? SimpleEmployeeDto.fromJson(json['sender'] as Map<String, dynamic>)
            : null,

        replyTo: (json['replyTo'] is Map && (json['replyTo'] as Map).isNotEmpty)
            ? MessageResponse.fromJson(json['replyTo'] as Map<String, dynamic>)
            : null,

        attachments: (json['attachments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(MessageAttachmentResponse.fromJson)
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

    // --- null-safe сериализация ---
    'sender': sender?.toJson(),

    'replyTo': replyTo?.toJson(),
    'attachments': attachments?.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
    id,
    text,
    sentAt,
    updatedAt,
    isDeleted,
    chatId,
    postId,
    sender,
    replyTo,
    attachments,
  ];
}

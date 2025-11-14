import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/chat/data/models/message/message_response.dart';

abstract class MessageRemoteDataSource {
  Future<List<MessageResponse>> getMessages(
    int chatId, {
    String? search,
    int skip,
    int take,
  });
  Future<int> getChatUnreadCount(int chatId);
  Future<void> sendTyping(int chatId);
  Future<MessageResponse> sendMessage(
    int chatId, {
    String? text,
    int? replyToId,
    int? postId,
    List<MultipartFile>? attachments,
  });
  Future<MessageResponse> updateMessage(int chatId, int messageId, String text);
  Future<void> deleteMessage(int chatId, int messageId);
  Future<void> markAsRead(int chatId);
}

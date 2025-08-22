import 'package:waypay/features/chat/data/models/chat/chat_link_response.dart';
import 'package:waypay/features/chat/data/models/chat/chat_member_response.dart';
import 'package:waypay/features/chat/data/models/chat/chat_response.dart';

abstract class ChatRemoteDataSource {
  Future<int> getUnreadCount();
  Future<List<ChatResponse>> getMyChats({String? search});
  Future<List<ChatMemberResponse>> getMembers(int chatId);
  Future<ChatResponse> getOrCreatePrivate(int targetUserId);
  Future<List<MessageAttachmentResponse>> getChatPhotos(
    int chatId, {
    int skip,
    int take,
  });
  Future<List<MessageAttachmentResponse>> getChatFiles(
    int chatId, {
    int skip,
    int take,
  });
  Future<List<MessageAttachmentResponse>> getChatVideos(
    int chatId, {
    int skip,
    int take,
  });
  Future<List<ChatLinkResponse>> getChatLinks(int chatId, {int skip, int take});
  Future<void> refreshChats();
  Future<void> deletePrivateChat(int chatId);
}

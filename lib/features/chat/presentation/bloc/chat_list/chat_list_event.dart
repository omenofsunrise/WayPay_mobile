part of 'chat_list_bloc.dart';

abstract class ChatListEvent {
  const ChatListEvent();
}

class ChatListStarted extends ChatListEvent {
  const ChatListStarted();
}

class ChatListRefreshed extends ChatListEvent {
  const ChatListRefreshed();
}

class ChatListSearchChanged extends ChatListEvent {
  final String query;
  const ChatListSearchChanged(this.query);
}

class ChatListChatOpened extends ChatListEvent {
  final int chatId;
  const ChatListChatOpened(this.chatId);
}

class _ChatListHubMessageReceived extends ChatListEvent {
  final Map<String, dynamic> message;
  const _ChatListHubMessageReceived(this.message);
}

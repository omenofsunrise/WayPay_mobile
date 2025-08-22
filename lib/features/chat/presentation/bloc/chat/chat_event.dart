part of 'chat_bloc.dart';

abstract class ChatEvent {
  const ChatEvent();
}

class ChatStarted extends ChatEvent {
  const ChatStarted();
}

class ChatLoadMore extends ChatEvent {
  const ChatLoadMore();
}

class ChatSend extends ChatEvent {
  final String? text;
  final List<MultipartFile>? attachments;
  final int? replyToId;
  const ChatSend({this.text, this.attachments, this.replyToId});
}

class ChatTyping extends ChatEvent {
  const ChatTyping();
}

class ChatUserTyping extends ChatEvent {
  final String? userName;
  const ChatUserTyping(this.userName);
}

class ChatMarkRead extends ChatEvent {
  const ChatMarkRead();
}

class ChatDispose extends ChatEvent {
  const ChatDispose();
}

/// входящее от хаба
class _ChatIncomingMessage extends ChatEvent {
  final Map<String, dynamic> json;
  const _ChatIncomingMessage(this.json);
}

/// ====== РЕДАКТИРОВАНИЕ ======
class ChatEditStart extends ChatEvent {
  final MessageResponse message;
  const ChatEditStart(this.message);
}

class ChatEditCancel extends ChatEvent {
  const ChatEditCancel();
}

class ChatEditConfirm extends ChatEvent {
  final int id;
  final String newText;
  const ChatEditConfirm({required this.id, required this.newText});
}

class ChatDelete extends ChatEvent {
  final int id;
  const ChatDelete({required this.id});
}

class ChatMembersRequested extends ChatEvent {
  const ChatMembersRequested();
}

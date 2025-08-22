import 'dart:async';

import 'package:dio/dio.dart' show MultipartFile;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay/features/chat/data/models/chat/chat_member_response.dart';
import 'package:waypay/features/chat/data/models/message/message_response.dart';
import 'package:waypay/features/chat/data/service/chat_hub_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessageRemoteDataSource messageApi;
  final ChatRemoteDataSource chatApi;
  final ChatHubService hub;
  final int chatId;

  StreamSubscription? _hubMsgSub;
  StreamSubscription? _hubTypingSub;

  int _skip = 0;
  final int _take = 50;
  bool _hasMore = true;

  ChatBloc({
    required this.messageApi,
    required this.chatApi,
    required this.hub,
    required this.chatId,
  }) : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatLoadMore>(_onLoadMore);
    on<ChatSend>(_onSend);
    on<ChatTyping>(_onTyping);
    on<ChatUserTyping>(_onUserTyping);
    on<_ChatIncomingMessage>(_onIncomingMessage);
    on<ChatMarkRead>(_onMarkRead);
    on<ChatDispose>(_onDispose);
    on<ChatEditStart>(_onEditStart);
    on<ChatEditCancel>(_onEditCancel);
    on<ChatEditConfirm>(_onEditConfirm);
    on<ChatDelete>(_onDelete);
    on<ChatMembersRequested>(_onMembersRequested);
  }

  Future<void> _onStarted(ChatStarted e, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await hub.connect();
      await hub.joinChat(chatId);

      _hubMsgSub ??= hub.onReceiveMessage.listen((m) {
        final midChat = (m['chatId'] as num?)?.toInt();
        if (midChat == chatId) add(_ChatIncomingMessage(m));
      });

      _hubTypingSub ??= hub.onUserTyping.listen((t) {
        if (t.chatId == chatId) add(ChatUserTyping(t.userName));
      });

      final msgs = await messageApi.getMessages(
        chatId,
        skip: _skip,
        take: _take,
      );
      _skip += msgs.length;
      _hasMore = msgs.length == _take;

      // Сортируем сообщения по убыванию ID (от новых к старым)
      msgs.sort((a, b) => b.id.compareTo(a.id));

      emit(state.copyWith(isLoading: false, messages: msgs, error: null));
      add(const ChatMarkRead());
    } catch (err) {
      emit(state.copyWith(isLoading: false, error: err.toString()));
    }
  }

  Future<void> _onMembersRequested(
    ChatMembersRequested e,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isMembersLoading: true, membersError: null));
    try {
      final members = await chatApi.getMembers(chatId);
      emit(state.copyWith(isMembersLoading: false, members: members));
    } catch (err) {
      emit(
        state.copyWith(isMembersLoading: false, membersError: err.toString()),
      );
    }
  }

  Future<void> _onLoadMore(ChatLoadMore e, Emitter<ChatState> emit) async {
    if (state.isPaging || !_hasMore) return;
    emit(state.copyWith(isPaging: true, error: null));
    try {
      final more = await messageApi.getMessages(
        chatId,
        skip: _skip,
        take: _take,
      );
      _skip += more.length;
      _hasMore = more.length == _take;

      emit(
        state.copyWith(isPaging: false, messages: [...state.messages, ...more]),
      );
    } catch (err) {
      emit(state.copyWith(isPaging: false, error: err.toString()));
    }
  }

  Future<void> _onSend(ChatSend e, Emitter<ChatState> emit) async {
    final hasText = (e.text != null && e.text!.trim().isNotEmpty);
    final hasFiles = (e.attachments != null && e.attachments!.isNotEmpty);
    if (!hasText && !hasFiles) return;

    if (state.editingMessageId != null) return;

    emit(state.copyWith(isSending: true, error: null));
    try {
      await messageApi.sendMessage(
        chatId,
        text: e.text?.trim(),
        replyToId: e.replyToId,
        attachments: e.attachments,
      );
      emit(state.copyWith(isSending: false));
    } catch (err) {
      emit(state.copyWith(isSending: false, error: err.toString()));
    }
  }

  Future<void> _onTyping(ChatTyping e, Emitter<ChatState> emit) async {
    try {
      await messageApi.sendTyping(chatId);
    } catch (_) {}
  }

  Future<void> _onUserTyping(ChatUserTyping e, Emitter<ChatState> emit) async {
    emit(state.copyWith(typingName: e.userName ?? '…'));
    await Future.delayed(const Duration(seconds: 3));
    if (!emit.isDone) emit(state.copyWith(typingName: null));
  }

  void _onIncomingMessage(_ChatIncomingMessage e, Emitter<ChatState> emit) {
    final msg = MessageResponse.fromJson(Map<String, dynamic>.from(e.json));

    final isDuplicate = state.messages.any((m) => m.id == msg.id);

    if (!isDuplicate) {
      // Добавляем новое сообщение в НАЧАЛО списка
      final updatedMessages = [msg, ...state.messages];
      emit(state.copyWith(messages: updatedMessages));
    }
  }

  Future<void> _onMarkRead(ChatMarkRead e, Emitter<ChatState> emit) async {
    try {
      await messageApi.markAsRead(chatId);
    } catch (_) {}
  }

  // ====== РЕДАКТИРОВАНИЕ ======
  void _onEditStart(ChatEditStart e, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        editingMessageId: e.message.id,
        editingOriginalText: e.message.text ?? '',
        error: null,
      ),
    );
  }

  void _onEditCancel(ChatEditCancel e, Emitter<ChatState> emit) {
    emit(
      state.copyWith(
        editingMessageId: null,
        editingOriginalText: null,
        isEditingInProgress: false,
      ),
    );
  }

  Future<void> _onEditConfirm(
    ChatEditConfirm e,
    Emitter<ChatState> emit,
  ) async {
    if (e.newText.trim().isEmpty) return;
    emit(state.copyWith(isEditingInProgress: true, error: null));
    try {
      final updated = await messageApi.updateMessage(
        chatId,
        e.id,
        e.newText.trim(),
      );

      final idx = state.messages.indexWhere((m) => m.id == e.id);
      if (idx != -1) {
        final copy = [...state.messages];
        copy[idx] = updated;

        // Важно: пересортируем после обновления, чтобы сохранить порядок
        copy.sort((a, b) => b.id.compareTo(a.id));

        emit(
          state.copyWith(
            messages: copy,
            isEditingInProgress: false,
            editingMessageId: null,
            editingOriginalText: null,
          ),
        );
      } else {
        emit(state.copyWith(isEditingInProgress: false));
      }
    } catch (err) {
      emit(state.copyWith(isEditingInProgress: false, error: err.toString()));
    }
  }

  Future<void> _onDelete(ChatDelete e, Emitter<ChatState> emit) async {
    emit(state.copyWith(deletingMessageId: e.id, error: null));

    try {
      // Удаляем на сервере
      await messageApi.deleteMessage(chatId, e.id);

      // Создаем новый список сообщений, исключая удаленное
      final updatedMessages = state.messages
          .where((m) => m.id != e.id)
          .toList();

      // Обновляем состояние
      emit(state.copyWith(messages: updatedMessages, deletingMessageId: null));
    } catch (err) {
      emit(state.copyWith(deletingMessageId: null, error: err.toString()));
    }
  }

  Future<void> _onDispose(ChatDispose e, Emitter<ChatState> emit) async {
    try {
      await hub.leaveChat(chatId);
    } catch (_) {}
    await _hubMsgSub?.cancel();
    await _hubTypingSub?.cancel();
  }

  @override
  Future<void> close() async {
    add(const ChatDispose());
    return super.close();
  }
}

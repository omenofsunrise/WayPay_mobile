import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:waypay/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay/features/chat/data/models/chat/chat_response.dart';
import 'package:waypay/features/chat/data/service/chat_hub_service.dart';

part 'chat_list_event.dart';
part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRemoteDataSource api;
  final ChatHubService hub;

  StreamSubscription? _hubSub;
  Timer? _debounce;

  ChatListBloc({required this.api, required this.hub})
    : super(ChatListState.initial()) {
    on<ChatListStarted>(_onStarted);
    on<ChatListRefreshed>(_onRefresh);
    on<ChatListSearchChanged>(_onSearchChanged);
    on<ChatListChatOpened>(_onChatOpened);
    on<_ChatListHubMessageReceived>(_onHubMessage);
  }

  Future<void> _onStarted(
    ChatListStarted e,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await hub.connect();
      _hubSub ??= hub.onReceiveMessage.listen(
        (m) => add(_ChatListHubMessageReceived(m)),
      );
      final chats = await api.getMyChats();
      final unread = await api.getUnreadCount();
      emit(state.copyWith(isLoading: false, chats: chats, totalUnread: unread));
    } catch (err) {
      emit(state.copyWith(isLoading: false, error: err.toString()));
    }
  }

  Future<void> _onRefresh(
    ChatListRefreshed e,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, error: null));
    try {
      await api.refreshChats();
      final chats = await api.getMyChats(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      final unread = await api.getUnreadCount();
      emit(
        state.copyWith(isRefreshing: false, chats: chats, totalUnread: unread),
      );
    } catch (err) {
      emit(state.copyWith(isRefreshing: false, error: err.toString()));
    }
  }

  Future<void> _onSearchChanged(
    ChatListSearchChanged e,
    Emitter<ChatListState> emit,
  ) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      emit(state.copyWith(searchQuery: e.query, isLoading: true, error: null));
      try {
        final chats = await api.getMyChats(
          search: e.query.isEmpty ? null : e.query,
        );
        final unread = await api.getUnreadCount();
        emit(
          state.copyWith(isLoading: false, chats: chats, totalUnread: unread),
        );
      } catch (err) {
        emit(state.copyWith(isLoading: false, error: err.toString()));
      }
    });
  }

  void _onChatOpened(ChatListChatOpened e, Emitter<ChatListState> emit) {
    final updated = state.chats.map((c) {
      if (c.id == e.chatId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    final newTotal = updated.fold<int>(
      0,
      (sum, c) => sum + (c.unreadCount ?? 0),
    );
    emit(state.copyWith(chats: updated, totalUnread: newTotal));
  }

  void _onHubMessage(
    _ChatListHubMessageReceived e,
    Emitter<ChatListState> emit,
  ) {
    final m = e.message;
    final chatId = (m['chatId'] as num?)?.toInt();
    if (chatId == null) return;

    final text = m['text'] as String?;
    final sentAtStr = m['sentAt'] as String?;
    final sentAt = sentAtStr != null ? DateTime.tryParse(sentAtStr) : null;

    bool found = false;
    final updated = state.chats.map((c) {
      if (c.id != chatId) return c;
      found = true;
      final lm = c.lastMessage?.copyWith(
        text: text ?? c.lastMessage?.text,
        sentAt: sentAt ?? c.lastMessage?.sentAt,
        isDeleted: false,
      );
      return c.copyWith(
        lastMessage: lm ?? c.lastMessage,
        unreadCount: (c.unreadCount ?? 0) + 1,
      );
    }).toList();

    if (!found) {
      add(const ChatListRefreshed());
      return;
    }

    final newTotal = updated.fold<int>(
      0,
      (sum, c) => sum + (c.unreadCount ?? 0),
    );
    emit(state.copyWith(chats: updated, totalUnread: newTotal));
  }

  @override
  Future<void> close() async {
    await _hubSub?.cancel();
    _debounce?.cancel();
    return super.close();
  }
}

part of 'chat_list_bloc.dart';

class ChatListState {
  final bool isLoading;
  final bool isRefreshing;
  final String searchQuery;
  final List<ChatResponse> chats;
  final int totalUnread;
  final String? error;

  const ChatListState({
    required this.isLoading,
    required this.isRefreshing,
    required this.searchQuery,
    required this.chats,
    required this.totalUnread,
    required this.error,
  });

  factory ChatListState.initial() => const ChatListState(
    isLoading: true,
    isRefreshing: false,
    searchQuery: '',
    chats: [],
    totalUnread: 0,
    error: null,
  );

  ChatListState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? searchQuery,
    List<ChatResponse>? chats,
    int? totalUnread,
    String? error,
  }) {
    return ChatListState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchQuery: searchQuery ?? this.searchQuery,
      chats: chats ?? this.chats,
      totalUnread: totalUnread ?? this.totalUnread,
      error: error,
    );
  }
}

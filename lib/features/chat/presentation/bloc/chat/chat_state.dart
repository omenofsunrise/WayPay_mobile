part of 'chat_bloc.dart';

class ChatState extends Equatable {
  final bool isLoading;
  final bool isPaging;
  final bool isSending;
  final String? error;
  final List<MessageResponse> messages;
  final String? typingName;
  final int? editingMessageId;
  final String? editingOriginalText;
  final bool isEditingInProgress;
  final int? deletingMessageId;
  final bool isMembersLoading;
  final List<ChatMemberResponse> members;
  final String? membersError;

  const ChatState({
    this.isLoading = false,
    this.isPaging = false,
    this.isSending = false,
    this.error,
    this.messages = const [],
    this.typingName,
    this.editingMessageId,
    this.editingOriginalText,
    this.isEditingInProgress = false,
    this.deletingMessageId,
    this.isMembersLoading = false,
    this.members = const [],
    this.membersError,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isPaging,
    bool? isSending,
    String? error,
    List<MessageResponse>? messages,
    String? typingName,
    int? editingMessageId,
    String? editingOriginalText,
    bool? isEditingInProgress,
    int? deletingMessageId,
    bool? isMembersLoading,
    List<ChatMemberResponse>? members,
    String? membersError,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isPaging: isPaging ?? this.isPaging,
      isSending: isSending ?? this.isSending,
      error: error,
      messages: messages ?? this.messages,
      typingName: typingName,
      editingMessageId: editingMessageId,
      editingOriginalText: editingOriginalText,
      isEditingInProgress: isEditingInProgress ?? this.isEditingInProgress,
      deletingMessageId: deletingMessageId,
      isMembersLoading: isMembersLoading ?? this.isMembersLoading,
      members: members ?? this.members,
      membersError: membersError,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isPaging,
    isSending,
    error,
    messages,
    typingName,
    editingMessageId,
    editingOriginalText,
    isEditingInProgress,
    deletingMessageId,
    isMembersLoading,
    members,
    membersError,
  ];
}

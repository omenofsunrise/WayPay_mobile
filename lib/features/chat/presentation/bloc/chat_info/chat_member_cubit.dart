import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/models/chat/chat_member_response.dart';

class ChatMembersState {
  final List<ChatMemberResponse> members;
  final bool loading;
  final String? error;

  ChatMembersState({required this.members, required this.loading, this.error});

  factory ChatMembersState.initial() =>
      ChatMembersState(members: [], loading: false);

  ChatMembersState copyWith({
    List<ChatMemberResponse>? members,
    bool? loading,
    String? error,
  }) {
    return ChatMembersState(
      members: members ?? this.members,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class ChatMembersCubit extends Cubit<ChatMembersState> {
  final ChatRemoteDataSource _dataSource = getIt<ChatRemoteDataSource>();
  final int chatId;

  ChatMembersCubit({required this.chatId}) : super(ChatMembersState.initial());

  Future<void> loadMembers() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final members = await _dataSource.getMembers(chatId);
      emit(state.copyWith(members: members, loading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), loading: false));
    }
  }
}

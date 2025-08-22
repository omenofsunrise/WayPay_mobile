import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay/features/chat/data/models/chat/chat_response.dart';

import 'paged_bloc.dart';

class ChatFilesBloc extends PagedBloc<MessageAttachmentResponse> {
  final int chatId;

  ChatFilesBloc({required this.chatId})
    : super(
        fetchPage: (({required int skip, required int take}) async {
          final token = await getIt<TokenStorage>().getAccessToken();
          if (token == null) throw Exception('Сессия истекла');
          return getIt<ChatRemoteDataSource>().getChatFiles(chatId, skip: skip, take: take);
        }),
      );
}

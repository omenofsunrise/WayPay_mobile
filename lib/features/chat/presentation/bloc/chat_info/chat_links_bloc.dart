import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/models/chat/chat_link_response.dart';
import 'paged_bloc.dart';

class ChatLinksBloc extends PagedBloc<ChatLinkResponse> {
  final int chatId;

  ChatLinksBloc({required this.chatId})
    : super(
        fetchPage: (({required int skip, required int take}) async {
          final token = await getIt<TokenStorage>().getAccessToken();
          if (token == null) throw Exception('Сессия истекла');
          return getIt<ChatRemoteDataSource>().getChatLinks(
            chatId,
            skip: skip,
            take: take,
          );
        }),
      );
}

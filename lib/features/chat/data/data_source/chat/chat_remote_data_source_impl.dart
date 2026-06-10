import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/models/chat/chat_link_response.dart';
import 'package:waypay_mobile/features/chat/data/models/chat/chat_member_response.dart';
import 'package:waypay_mobile/features/chat/data/models/chat/chat_response.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSourceImpl(this.dio);

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get(
        'Chats/unread-count',
        options: Options(responseType: ResponseType.plain),
      );

      final data = response.data;
      if (data is int) return data;
      if (data is String) {
        final v = int.tryParse(data.trim());
        if (v != null) return v;
      }
      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить количество непрочитанных.',
      );
    }
  }

  @override
  Future<List<ChatResponse>> getMyChats({String? search}) async {
    try {
      final response = await dio.get(
        'Chats/my',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(ChatResponse.fromJson)
            .toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить чаты.');
    }
  }

  @override
  Future<List<ChatMemberResponse>> getMembers(int chatId) async {
    try {
      final response = await dio.get('Chats/$chatId/members');

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(ChatMemberResponse.fromJson)
            .toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить участников чата.');
    }
  }

  @override
  Future<ChatResponse> getOrCreatePrivate(int targetUserId) async {
    try {
      final response = await dio.get('Chats/private/$targetUserId');

      final data = response.data;
      if (data == null) {
        throw const ApiError('Сервер вернул пустой ответ.');
      }

      if (data is Map<String, dynamic>) {
        return ChatResponse.fromJson(data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось открыть приватный чат.');
    }
  }

  @override
  Future<List<MessageAttachmentResponse>> getChatPhotos(
    int chatId, {
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final response = await dio.get(
        'Chats/$chatId/photos',
        queryParameters: {'skip': skip, 'take': take},
        options: Options(
          responseType: ResponseType.json,
          headers: {'accept': 'text/plain'},
        ),
      );

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(MessageAttachmentResponse.fromJson)
            .toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить фото чата.');
    }
  }

  @override
  Future<List<MessageAttachmentResponse>> getChatFiles(
    int chatId, {
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final response = await dio.get(
        'Chats/$chatId/files',
        queryParameters: {'skip': skip, 'take': take},
        options: Options(
          responseType: ResponseType.json,
          headers: {'accept': 'text/plain'},
        ),
      );

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(MessageAttachmentResponse.fromJson)
            .toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить файлы чата.');
    }
  }

  @override
  Future<List<MessageAttachmentResponse>> getChatVideos(
    int chatId, {
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final response = await dio.get(
        'Chats/$chatId/videos',
        queryParameters: {'skip': skip, 'take': take},
        options: Options(
          responseType: ResponseType.json,
          headers: {'accept': 'text/plain'},
        ),
      );

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(MessageAttachmentResponse.fromJson)
            .toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить видео чата.');
    }
  }

  @override
  Future<List<ChatLinkResponse>> getChatLinks(
    int chatId, {
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final response = await dio.get(
        'Chats/$chatId/links',
        queryParameters: {'skip': skip, 'take': take},
        options: Options(
          responseType: ResponseType.json,
          headers: {'accept': 'text/plain'},
        ),
      );

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(ChatLinkResponse.fromJson)
            .toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить ссылки чата.');
    }
  }

  @override
  Future<void> refreshChats() async {
    try {
      final response = await dio.post('Chats/refresh-chats');
      if (response.statusCode != 200) {
        throw const ApiError('Не удалось обновить чаты.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить чаты.');
    }
  }

  @override
  Future<void> deletePrivateChat(int chatId) async {
    try {
      final response = await dio.delete('Chats/private/$chatId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ApiError('Не удалось удалить приватный чат.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить приватный чат.');
    }
  }
}

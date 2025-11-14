import 'package:dio/dio.dart';
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
        '/api/Chats/unread-count',
        options: Options(responseType: ResponseType.plain),
      );

      final data = response.data;
      if (data is int) return data;
      if (data is String) {
        final v = int.tryParse(data.trim());
        if (v != null) return v;
      }
      throw Exception('Неожиданный формат ответа');
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки количества непрочитанных: ${e.message}');
    }
  }

  @override
  Future<List<ChatResponse>> getMyChats({String? search}) async {
    try {
      final response = await dio.get(
        '/api/Chats/my',
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
        throw Exception('Неожиданный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки чатов: ${e.message}');
    }
  }

  @override
  Future<List<ChatMemberResponse>> getMembers(int chatId) async {
    try {
      final response = await dio.get('/api/Chats/$chatId/members');

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(ChatMemberResponse.fromJson)
            .toList();
      } else {
        throw Exception('Неожиданный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки участников чата: ${e.message}');
    }
  }

  @override
  Future<ChatResponse> getOrCreatePrivate(int targetUserId) async {
    try {
      final response = await dio.get('/api/Chats/private/$targetUserId');

      final data = response.data;
      if (data == null) {
        throw Exception('Пустой ответ от сервера');
      }

      if (data is Map<String, dynamic>) {
        return ChatResponse.fromJson(data);
      } else {
        throw Exception('Неожиданный формат ответа: ${data.runtimeType}');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка открытия приватного чата: ${e.message}');
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
        '/api/Chats/$chatId/photos',
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
        throw Exception('Неожиданный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки фото чата: ${e.message}');
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
        '/api/Chats/$chatId/files',
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
        throw Exception('Неожиданный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки файлов чата: ${e.message}');
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
        '/api/Chats/$chatId/videos',
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
        throw Exception('Неожиданный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки видео чата: ${e.message}');
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
        '/api/Chats/$chatId/links',
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
        throw Exception('Неожиданный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки ссылок чата: ${e.message}');
    }
  }

  @override
  Future<void> refreshChats() async {
    try {
      final response = await dio.post('/api/Chats/refresh-chats');
      if (response.statusCode != 200) {
        throw Exception('Ошибка обновления чатов');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка обновления чатов: ${e.message}');
    }
  }

  @override
  Future<void> deletePrivateChat(int chatId) async {
    try {
      final response = await dio.delete('/api/Chats/private/$chatId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Ошибка при удалении приватного чата');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка при удалении приватного чата: ${e.message}');
    }
  }
}

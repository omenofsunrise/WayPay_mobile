import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/models/message/message_response.dart';

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final Dio dio;

  MessageRemoteDataSourceImpl(this.dio);

  @override
  Future<List<MessageResponse>> getMessages(
    int chatId, {
    int skip = 0,
    int take = 50,
    String? search,
  }) async {
    try {
      final response = await dio.get(
        'chats/$chatId/Messages',
        queryParameters: {
          'skip': skip,
          'take': take,
          if (search != null && search.isNotEmpty) 'search': search,
        },
        options: Options(headers: {'accept': 'text/plain'}),
      );

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map(MessageResponse.fromJson)
            .toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить сообщения.');
    }
  }

  @override
  Future<int> getChatUnreadCount(int chatId) async {
    try {
      final response = await dio.get(
        'chats/$chatId/Messages/unread-count',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'accept': 'text/plain'},
        ),
      );

      final data = response.data;
      if (data is int) return data;
      if (data is String) return int.tryParse(data.trim()) ?? 0;

      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить количество непрочитанных сообщений.',
      );
    }
  }

  @override
  Future<void> sendTyping(int chatId) async {
    try {
      final response = await dio.post('chats/$chatId/Messages/typing');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ApiError('Не удалось отправить событие набора текста.');
      }
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось отправить событие набора текста.',
      );
    }
  }

  @override
  Future<MessageResponse> sendMessage(
    int chatId, {
    String? text,
    int? replyToId,
    int? postId,
    List<MultipartFile>? attachments,
  }) async {
    try {
      final formData = FormData();

      if (text != null) formData.fields.add(MapEntry('Text', text));
      if (replyToId != null) {
        formData.fields.add(MapEntry('ReplyToId', replyToId.toString()));
      }
      if (postId != null) {
        formData.fields.add(MapEntry('PostId', postId.toString()));
      }
      if (attachments != null && attachments.isNotEmpty) {
        for (final file in attachments) {
          formData.files.add(MapEntry('Attachments', file));
        }
      }

      final response = await dio.post(
        'chats/$chatId/Messages',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'accept': 'text/plain'},
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return MessageResponse.fromJson(response.data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось отправить сообщение.');
    }
  }

  @override
  Future<MessageResponse> updateMessage(
    int chatId,
    int messageId,
    String text,
  ) async {
    try {
      final response = await dio.put(
        'chats/$chatId/Messages/$messageId',
        data: jsonEncode(text),
        options: Options(
          contentType: 'application/json',
          headers: {'accept': 'text/plain'},
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return MessageResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось отредактировать сообщение.');
    }
  }

  @override
  Future<void> deleteMessage(int chatId, int messageId) async {
    try {
      final response = await dio.delete(
        'chats/$chatId/Messages/$messageId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ApiError('Не удалось удалить сообщение.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить сообщение.');
    }
  }

  @override
  Future<void> markAsRead(int chatId) async {
    try {
      final response = await dio.post('chats/$chatId/Messages/read');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ApiError('Не удалось отметить сообщения прочитанными.');
      }
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось отметить сообщения прочитанными.',
      );
    }
  }
}

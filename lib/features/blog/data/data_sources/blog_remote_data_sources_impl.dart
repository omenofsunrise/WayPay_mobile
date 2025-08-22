import 'package:dio/dio.dart';
import 'package:waypay/features/blog/data/models/blog_post_response_paged_result.dart';
import 'package:waypay/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay/features/blog/data/models/comment_response.dart';

class BlogRemoteDataSourcesImpl implements BlogRemoteDataSources {
  final Dio dio;

  BlogRemoteDataSourcesImpl(this.dio);

  @override
  Future<BlogPostResponsePagedResult> getBlogPosts({
    String? filter,
    String? sortBy,
    String? search,
    int? authorId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        '/api/Blog',
        queryParameters: {
          if (filter != null) 'Filter': filter,
          if (sortBy != null) 'SortBy': sortBy,
          if (search != null) 'Search': search,
          if (authorId != null) 'AuthorId': authorId,
          'Page': page,
          'PageSize': pageSize,
        },
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return BlogPostResponsePagedResult.fromJson(data);
      } else {
        throw Exception(
          'Неожиданный формат данных: ожидается объект с пагинацией',
        );
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения списка постов: ${e.message}');
    }
  }

  @override
  Future<void> createBlogPost({
    required String content,
    List<MultipartFile>? images,
    List<MultipartFile>? files,
  }) async {
    try {
      final formData = FormData();

      formData.fields.add(MapEntry('Content', content));

      if (images != null && images.isNotEmpty) {
        for (final img in images) {
          formData.files.add(MapEntry('Images', img));
        }
      }

      if (files != null && files.isNotEmpty) {
        for (final file in files) {
          formData.files.add(MapEntry('Files', file));
        }
      }

      await dio.post(
        '/api/Blog',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      print('Ответ сервера: ${e.response?.data}');
      throw Exception('Ошибка при создании поста: ${e.message}');
    }
  }

  @override
  Future<void> publishPost(int id) async {
    try {
      await dio.put('/api/Blog/$id/publish');
    } on DioException catch (e) {
      throw Exception('Ошибка публикации поста: ${e.message}');
    }
  }

  @override
  Future<void> deleteAttachment(int postId, int attachmentId) async {
    try {
      await dio.delete('/api/Blog/$postId/attachments/$attachmentId');
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при удалении вложения (postId=$postId, attachmentId=$attachmentId): ${e.message}',
      );
    }
  }

  @override
  Future<void> deletePost(int postId) async {
    try {
      await dio.delete('/api/Blog/$postId');
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при удалении поста (postId=$postId): ${e.message}',
      );
    }
  }

  @override
  Future<void> likePost(int postId) async {
    try {
      await dio.post('/api/Blog/$postId/like');
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при добавлении лайка (postId=$postId): ${e.message}',
      );
    }
  }

  @override
  Future<Response<dynamic>> downloadAttachment(int attachmentId) async {
    try {
      final response = await dio.get(
        '/api/Blog/attachments/$attachmentId/download',
        options: Options(responseType: ResponseType.bytes),
      );

      return response;
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при скачивании вложения (attachmentId=$attachmentId): ${e.message}',
      );
    }
  }

  @override
  Future<CommentResponse> createComment({
    required int postId,
    int? parentId,
    required String content,
    List<MultipartFile>? attachments,
  }) async {
    try {
      final formData = FormData();

      formData.fields.add(MapEntry('PostId', postId.toString()));
      formData.fields.add(MapEntry('Content', content));
      if (parentId != null) {
        formData.fields.add(MapEntry('ParentId', parentId.toString()));
      }

      if (attachments != null && attachments.isNotEmpty) {
        for (final file in attachments) {
          formData.files.add(MapEntry('Attachments', file));
        }
      }

      final response = await dio.post('/api/BlogComment', data: formData);

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return CommentResponse.fromJson(data);
      } else {
        throw Exception('Неверный формат ответа при создании комментария');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка создания комментария: ${e.message}');
    }
  }

  @override
  Future<List<CommentResponse>> getCommentsByPostId(int postId) async {
    try {
      final response = await dio.get('/api/BlogComment/post/$postId');

      final data = response.data;
      if (data is List) {
        return data.map((e) => CommentResponse.fromJson(e)).toList();
      } else {
        throw Exception(
          'Неверный формат ответа: ожидается список комментариев',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при получении комментариев для поста $postId: ${e.message}',
      );
    }
  }

  @override
  Future<void> likeComment(int commentId) async {
    try {
      await dio.post('/api/BlogComment/$commentId/like');
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при добавлении лайка комментарию (id=$commentId): ${e.message}',
      );
    }
  }

  @override
  Future<void> updateCommentText({
    required int commentId,
    required String newText,
  }) async {
    try {
      await dio.put(
        '/api/BlogComment/$commentId/text',
        data: '"$newText"',
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при обновлении текста комментария (id=$commentId): ${e.message}',
      );
    }
  }

  @override
  Future<void> deleteComment(int commentId) async {
    try {
      await dio.delete('/api/BlogComment/$commentId');
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при удалении комментария (id=$commentId): ${e.message}',
      );
    }
  }

  @override
  Future<void> deleteCommentAttachment({
    required int commentId,
    required int attachmentId,
  }) async {
    try {
      await dio.delete('/api/BlogComment/$commentId/attachments/$attachmentId');
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при удалении вложения (commentId=$commentId, attachmentId=$attachmentId): ${e.message}',
      );
    }
  }

  @override
  Future<CommentResponse> uploadCommentAttachment({
    required int commentId,
    required MultipartFile file,
  }) async {
    final formData = FormData.fromMap({'file': file});

    final response = await dio.post(
      '/api/BlogComment/$commentId/attachments',
      data: formData,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CommentResponse.fromJson(data);
    } else {
      throw Exception('Неверный ответ при добавлении вложения');
    }
  }
}

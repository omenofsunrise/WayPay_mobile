import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/blog/data/models/blog_post_response.dart';
import 'package:waypay_mobile/features/blog/data/models/blog_post_response_paged_result.dart';
import 'package:waypay_mobile/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay_mobile/features/blog/data/models/comment_response.dart';

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
        'Blog',
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
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить список постов.');
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
        'Blog',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать пост.');
    }
  }

  @override
  Future<void> publishPost(int id) async {
    try {
      await dio.put('Blog/$id/publish');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось опубликовать пост.');
    }
  }

  @override
  Future<void> deleteAttachment(int postId, int attachmentId) async {
    try {
      await dio.delete('Blog/$postId/attachments/$attachmentId');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить вложение.');
    }
  }

  @override
  Future<void> deletePost(int postId) async {
    try {
      await dio.delete('Blog/$postId');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить пост.');
    }
  }

  @override
  Future<void> likePost(int postId) async {
    try {
      await dio.post('Blog/$postId/like');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось поставить лайк.');
    }
  }

  @override
  Future<Response<dynamic>> downloadAttachment(int attachmentId) async {
    try {
      final response = await dio.get(
        'Blog/attachments/$attachmentId/download',
        options: Options(responseType: ResponseType.bytes),
      );

      return response;
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось скачать вложение.');
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

      final response = await dio.post('BlogComment', data: formData);

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return CommentResponse.fromJson(data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать комментарий.');
    }
  }

  @override
  Future<List<CommentResponse>> getCommentsByPostId(int postId) async {
    try {
      final response = await dio.get('BlogComment/post/$postId');

      final data = response.data;
      if (data is List) {
        return data.map((e) => CommentResponse.fromJson(e)).toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить комментарии.');
    }
  }

  @override
  Future<void> likeComment(int commentId) async {
    try {
      await dio.post('BlogComment/$commentId/like');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось поставить лайк комментарию.');
    }
  }

  @override
  Future<void> updateCommentText({
    required int commentId,
    required String newText,
  }) async {
    try {
      await dio.put(
        'BlogComment/$commentId/text',
        data: '"$newText"',
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить комментарий.');
    }
  }

  @override
  Future<void> deleteComment(int commentId) async {
    try {
      await dio.delete('BlogComment/$commentId');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить комментарий.');
    }
  }

  @override
  Future<void> deleteCommentAttachment({
    required int commentId,
    required int attachmentId,
  }) async {
    try {
      await dio.delete('BlogComment/$commentId/attachments/$attachmentId');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить вложение.');
    }
  }

  @override
  Future<CommentResponse> uploadCommentAttachment({
    required int commentId,
    required MultipartFile file,
  }) async {
    final formData = FormData.fromMap({'file': file});

    final response = await dio.post(
      'BlogComment/$commentId/attachments',
      data: formData,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CommentResponse.fromJson(data);
    } else {
      throw const ApiError('Сервер вернул некорректный ответ.');
    }
  }

  @override
  Future<BlogPostResponse> getBlogPostById(int id) async {
    try {
      final response = await dio.get('Blog/$id');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return BlogPostResponse.fromJson(data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить пост.');
    }
  }
}

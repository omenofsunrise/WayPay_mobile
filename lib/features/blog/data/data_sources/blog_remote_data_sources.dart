import 'package:dio/dio.dart';
import 'package:waypay/features/blog/data/models/blog_post_response.dart';
import 'package:waypay/features/blog/data/models/blog_post_response_paged_result.dart';
import 'package:waypay/features/blog/data/models/comment_response.dart';

abstract class BlogRemoteDataSources {
  Future<BlogPostResponsePagedResult> getBlogPosts({
    String? filter,
    String? sortBy,
    String? search,
    int? authorId,
    int page = 1,
    int pageSize = 20,
  });
  Future<void> createBlogPost({required String content, List<MultipartFile>? images, List<MultipartFile>? files});
  Future<BlogPostResponse> getBlogPostById(int id);
  Future<void> publishPost(int id);
  Future<void> deleteAttachment(int postId, int attachmentId);
  Future<void> deletePost(int postId);
  Future<void> likePost(int postId);
  Future<Response<dynamic>> downloadAttachment(int attachmentId);
  Future<CommentResponse> createComment({
    required int postId,
    int? parentId,
    required String content,
    List<MultipartFile>? attachments,
  });
  Future<List<CommentResponse>> getCommentsByPostId(int postId);
  Future<void> likeComment(int commentId);
  Future<void> updateCommentText({required int commentId, required String newText});
  Future<void> deleteComment(int commentId);
  Future<void> deleteCommentAttachment({required int commentId, required int attachmentId});
  Future<CommentResponse> uploadCommentAttachment({required int commentId, required MultipartFile file});
}

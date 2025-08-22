import 'package:waypay/features/blog/data/models/file_attachment_response.dart';

class BlogPostResponse {
  final int id;
  final String? authorName;
  final String? authorAvatarPath;
  final int authorId;
  final String? content;
  final bool isPublished;
  final DateTime createdAt;
  final List<String>? imageUrls;
  final List<FileAttachmentResponse>? attachments;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByCurrentUser;
  final bool isAuthor;

  BlogPostResponse({
    required this.id,
    this.authorName,
    this.authorAvatarPath,
    required this.authorId,
    this.content,
    required this.isPublished,
    required this.createdAt,
    this.imageUrls,
    this.attachments,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByCurrentUser,
    required this.isAuthor,
  });

  factory BlogPostResponse.fromJson(Map<String, dynamic> json) {
    return BlogPostResponse(
      id: json['id'] as int,
      authorName: json['authorName'] as String?,
      authorAvatarPath: json['authorAvatarPath'] as String?,
      authorId: json['authorId'] as int,
      content: json['content'] as String?,
      isPublished: json['isPublished'] as bool,
      createdAt: DateTime.parse(json['createdAt']),
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((e) => FileAttachmentResponse.fromJson(e)).toList()
          : null,
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool,
      isAuthor: json['isAuthor'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatarPath': authorAvatarPath,
      'authorId': authorId,
      'content': content,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': imageUrls,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'isAuthor': isAuthor,
    };
  }

  BlogPostResponse copyWith({
    String? content,
    List<String>? imageUrls,
    List<FileAttachmentResponse>? attachments,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByCurrentUser,
  }) {
    return BlogPostResponse(
      id: id,
      authorName: authorName,
      authorAvatarPath: authorAvatarPath,
      authorId: authorId,
      content: content ?? this.content,
      isPublished: isPublished,
      createdAt: createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      attachments: attachments ?? this.attachments,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isAuthor: isAuthor,
    );
  }
}

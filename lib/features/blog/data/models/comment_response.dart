import 'package:waypay/features/blog/data/models/comment_attachment_response.dart';

class CommentResponse {
  final int id;
  final int postId;
  final int authorId;
  final String? authorName;
  final String? authorPhotoPath;
  final String? content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? parentId;
  final int likeCount;
  final bool isLikedByCurrentUser;
  final List<CommentAttachmentResponse>? attachments;
  final List<CommentResponse> replies;

  CommentResponse({
    required this.id,
    required this.postId,
    required this.authorId,
    this.authorName,
    this.authorPhotoPath,
    this.content,
    required this.createdAt,
    this.updatedAt,
    this.parentId,
    required this.likeCount,
    required this.isLikedByCurrentUser,
    this.attachments,
    this.replies = const [],
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      id: json['id'] as int,
      postId: json['postId'] as int,
      authorId: json['authorId'] as int,
      authorName: json['authorName'] as String?,
      authorPhotoPath: json['authorPhotoPath'] as String?,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      parentId: json['parentId'] as int?,
      likeCount: json['likeCount'] as int,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List<dynamic>)
                .map((e) => CommentAttachmentResponse.fromJson(e))
                .toList()
          : null,
      replies: json['replies'] != null
          ? (json['replies'] as List<dynamic>)
                .map((e) => CommentResponse.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoPath': authorPhotoPath,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'parentId': parentId,
      'likeCount': likeCount,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  CommentResponse copyWith({
    int? likeCount,
    bool? isLikedByCurrentUser,
    List<CommentResponse>? replies,
    String? content,
  }) {
    return CommentResponse(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorPhotoPath: authorPhotoPath,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      parentId: parentId,
      likeCount: likeCount ?? this.likeCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      attachments: attachments,
      replies: replies ?? this.replies,
    );
  }
}

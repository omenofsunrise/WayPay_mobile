import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class CommentEvent extends Equatable {
  const CommentEvent();

  @override
  List<Object?> get props => [];
}

class LoadComments extends CommentEvent {
  final int postId;
  const LoadComments(this.postId);

  @override
  List<Object?> get props => [postId];
}

class ToggleLikeComment extends CommentEvent {
  final int commentId;

  const ToggleLikeComment(this.commentId);

  @override
  List<Object?> get props => [commentId];
}

class CreateComment extends CommentEvent {
  final int postId;
  final int? parentId;
  final String content;
  final List<MultipartFile>? attachments;

  const CreateComment({
    required this.postId,
    this.parentId,
    required this.content,
    this.attachments,
  });

  @override
  List<Object?> get props => [postId, parentId, content, attachments];
}

class DeleteComment extends CommentEvent {
  final int commentId;
  final int postId;

  const DeleteComment({required this.commentId, required this.postId});
}

class UpdateCommentText extends CommentEvent {
  final int commentId;
  final String newText;
  final int postId;

  const UpdateCommentText({
    required this.commentId,
    required this.newText,
    required this.postId,
  });
}

class AddCommentAttachment extends CommentEvent {
  final int commentId;
  final MultipartFile file;
  final int postId;

  const AddCommentAttachment({
    required this.commentId,
    required this.file,
    required this.postId,
  });
}

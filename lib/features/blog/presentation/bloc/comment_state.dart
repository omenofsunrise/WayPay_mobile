import 'package:equatable/equatable.dart';
import 'package:waypay/features/blog/data/models/comment_response.dart';

abstract class CommentState extends Equatable {
  const CommentState();

  @override
  List<Object?> get props => [];
}

class CommentInitial extends CommentState {}

class CommentLoading extends CommentState {}

class CommentLoaded extends CommentState {
  final List<CommentResponse> comments;

  const CommentLoaded(this.comments);

  @override
  List<Object?> get props => [comments];
}

class CommentError extends CommentState {
  final String message;
  const CommentError(this.message);

  @override
  List<Object?> get props => [message];
}

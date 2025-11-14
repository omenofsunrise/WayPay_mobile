import 'package:equatable/equatable.dart';
import 'package:waypay_mobile/features/blog/data/models/blog_post_response.dart';
import 'package:waypay_mobile/features/blog/data/models/blog_post_response_paged_result.dart';

abstract class BlogState extends Equatable {
  const BlogState();

  @override
  List<Object?> get props => [];
}

class BlogInitial extends BlogState {}

class BlogLoading extends BlogState {}

class BlogLoaded extends BlogState {
  final BlogPostResponsePagedResult posts;
  const BlogLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

class BlogError extends BlogState {
  final String message;
  const BlogError(this.message);

  @override
  List<Object?> get props => [message];
}

class BlogPostLoaded extends BlogState {
  final BlogPostResponse post;
  const BlogPostLoaded(this.post);

  @override
  List<Object?> get props => [post];
}

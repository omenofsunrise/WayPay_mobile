import 'package:equatable/equatable.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/blog_screen.dart';

abstract class BlogEvent extends Equatable {
  const BlogEvent();

  @override
  List<Object?> get props => [];
}

class LoadBlogPosts extends BlogEvent {
  final FeedType feedType;
  final SortType sortType;
  final String? search;
  final int? authorId;

  const LoadBlogPosts({
    required this.feedType,
    required this.sortType,
    this.search,
    this.authorId,
  });

  @override
  List<Object?> get props => [feedType, sortType, authorId];
}

class ToggleLikePost extends BlogEvent {
  final int postId;

  const ToggleLikePost(this.postId);

  @override
  List<Object?> get props => [postId];
}

class ToggleLikeChatPost extends BlogEvent {
  final int postId;

  const ToggleLikeChatPost(this.postId);

  @override
  List<Object?> get props => [postId];
}

class LoadBlogPostById extends BlogEvent {
  final int postId;

  const LoadBlogPostById(this.postId);
  @override
  List<Object?> get props => [postId];
}

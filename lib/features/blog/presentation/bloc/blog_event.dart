import 'package:equatable/equatable.dart';
import 'package:waypay/features/blog/presentation/screens/blog_screen.dart';

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

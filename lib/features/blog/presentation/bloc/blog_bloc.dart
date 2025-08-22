import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay/features/blog/presentation/screens/blog_screen.dart';
import 'blog_event.dart';
import 'blog_state.dart';

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  BlogBloc() : super(BlogInitial()) {
    on<LoadBlogPosts>(_onLoadPosts);
    on<ToggleLikePost>(_onToggleLikePost);
  }

  Future<void> _onLoadPosts(
    LoadBlogPosts event,
    Emitter<BlogState> emit,
  ) async {
    emit(BlogLoading());

    try {
      final posts = await getIt<BlogRemoteDataSources>().getBlogPosts(
        filter: _filterForFeed(event.feedType),
        sortBy: _sortByForSort(event.sortType),
        search: event.search,
        authorId: event.authorId,
      );

      emit(BlogLoaded(posts));
    } catch (e) {
      emit(BlogError(e.toString()));
    }
  }

  Future<void> _onToggleLikePost(
    ToggleLikePost event,
    Emitter<BlogState> emit,
  ) async {
    if (state is BlogLoaded) {
      final current = state as BlogLoaded;

      final updated = current.posts.items!.map((p) {
        if (p.id == event.postId) {
          final alreadyLiked = p.isLikedByCurrentUser;
          return p.copyWith(
            isLikedByCurrentUser: !alreadyLiked,
            likesCount: alreadyLiked ? p.likesCount - 1 : p.likesCount + 1,
          );
        }
        return p;
      }).toList();

      emit(BlogLoaded(current.posts.copyWith(items: updated)));
    }

    try {
      await getIt<BlogRemoteDataSources>().likePost(event.postId);
    } catch (_) {}
  }

  String? _filterForFeed(FeedType type) {
    switch (type) {
      case FeedType.all:
        return null;
      case FeedType.myBlog:
        return 'mine';
      case FeedType.liked:
        return 'liked';
    }
  }

  String? _sortByForSort(SortType sort) {
    switch (sort) {
      case SortType.date:
        return 'Date';
      case SortType.likes:
        return 'Likes';
      case SortType.comments:
        return 'Comments';
    }
  }
}

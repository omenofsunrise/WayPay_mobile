import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/blog_screen.dart';
import 'blog_event.dart';
import 'blog_state.dart';

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  BlogBloc() : super(BlogInitial()) {
    on<LoadBlogPosts>(_onLoadPosts);
    on<ToggleLikePost>(_onToggleLikePost);
    on<LoadBlogPostById>(_onLoadPostById);
    on<ToggleLikeChatPost>(_onToggleLikeChatPost);
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

  Future<void> _onLoadPostById(
    LoadBlogPostById event,
    Emitter<BlogState> emit,
  ) async {
    emit(BlogLoading());

    try {
      final post = await getIt<BlogRemoteDataSources>().getBlogPostById(
        event.postId,
      );

      emit(BlogPostLoaded(post));
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

  Future<void> _onToggleLikeChatPost(
    ToggleLikeChatPost event,
    Emitter<BlogState> emit,
  ) async {
    if (state is BlogPostLoaded) {
      final current = state as BlogPostLoaded;

      if (current.post.id == event.postId) {
        final alreadyLiked = current.post.isLikedByCurrentUser;
        final updatedPost = current.post.copyWith(
          isLikedByCurrentUser: !alreadyLiked,
          likesCount: alreadyLiked
              ? current.post.likesCount - 1
              : current.post.likesCount + 1,
        );

        emit(BlogPostLoaded(updatedPost));
      }
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_event.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_state.dart';
import 'package:waypay_mobile/features/blog/presentation/cubit/profile_blog_cubit.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/blog_screen.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/comments_screen.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/create_post_screen.dart';
import 'package:waypay_mobile/features/blog/presentation/widgets/post_card.dart';
import 'package:waypay_mobile/features/blog/presentation/widgets/profile_blog_card.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ProfileBlogScreen extends StatefulWidget {
  final int id;
  const ProfileBlogScreen({super.key, required this.id});

  @override
  State<ProfileBlogScreen> createState() => _ProfileBlogScreenState();
}

class _ProfileBlogScreenState extends State<ProfileBlogScreen> {
  late final BlogBloc _blogBloc;
  int? userId;
  String? avatar;
  final _tokenStorage = TokenStorage();
  final userStorage = getIt<AuthRemoteDataSource>();

  @override
  void initState() {
    super.initState();
    context.read<ProfileBlogCubit>().loadProfile(widget.id);
    _loadUserId();

    _blogBloc = BlogBloc();
    _blogBloc.add(
      LoadBlogPosts(
        feedType: FeedType.all,
        sortType: SortType.date,
        authorId: widget.id,
      ),
    );
  }

  @override
  void dispose() {
    _blogBloc.close();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final info = await userStorage.getAuthInfo();
    final employeeJson = info['employee'] as Map<String, dynamic>?;
    final int id = employeeJson!['id'];
    setState(() {
      userId = id;
      avatar = employeeJson['photoPath'];
    });
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.lightGreyBackground),
      body: BlocBuilder<ProfileBlogCubit, ProfileBlogState>(
        builder: (context, state) {
          if (state is ProfileBlogLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state is ProfileBlogError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (state.message.contains('Сессия')) {
                          _logout();
                        } else {
                          context.read<ProfileBlogCubit>().loadProfile(
                            widget.id,
                          );
                        }
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ProfileBlogLoaded) {
            if (userId == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = state.profile;
            return Refresher(
              onRefresh: () async {
                context.read<ProfileBlogCubit>().loadProfile(widget.id);
                _blogBloc.add(
                  LoadBlogPosts(
                    feedType: FeedType.all,
                    sortType: SortType.date,
                    authorId: widget.id,
                  ),
                );
              },
              content: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    ProfileBlogCard(user: user, userId: userId!),
                    const SizedBox(height: 20),
                    if (userId == user.id)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePostScreen(),
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 40,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(AppColors.background),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Color(AppColors.greyLight),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+ Создать пост',
                                  style: AppStyle.manrope(
                                    size: 14,
                                    weight: FontWeight.w500,
                                    color: Color(AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    BlocProvider.value(
                      value: _blogBloc,
                      child: BlocBuilder<BlogBloc, BlogState>(
                        builder: (context, state) {
                          if (state is BlogLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is BlogError) {
                            return Center(
                              child: Text('Ошибка: ${state.message}'),
                            );
                          }
                          if (state is BlogLoaded) {
                            final posts = state.posts.items ?? [];
                            if (posts.isEmpty) {
                              return const Center(child: Text('Нет постов'));
                            }
                            return Column(
                              children: posts
                                  .map(
                                    (post) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: PostCard(
                                        id: post.id,
                                        authorId: post.authorId,
                                        author:
                                            post.authorName ?? 'Неизвестный',
                                        timeAgo: DateFormat(
                                          'dd.MM.yyyy HH:mm',
                                        ).format(post.createdAt),
                                        text: post.content ?? '',
                                        imageUrl:
                                            (post.imageUrls != null &&
                                                post.imageUrls!.isNotEmpty)
                                            ? post.imageUrls!.first
                                            : null,
                                        likes: post.likesCount,
                                        comments: post.commentsCount,
                                        authorAvatarPath: post.authorAvatarPath,
                                        isLiked: post.isLikedByCurrentUser,
                                        isAuthor: post.isAuthor,
                                        onLikePressed: () {
                                          context.read<BlogBloc>().add(
                                            ToggleLikePost(post.id),
                                          );
                                        },
                                        onCommentsPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CommentsScreen(
                                                postId: post.id,
                                                isAuthor: post.isAuthor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}

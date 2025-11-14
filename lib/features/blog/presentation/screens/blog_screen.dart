import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/comments_screen.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/create_post_screen.dart';
import 'package:waypay_mobile/features/blog/presentation/widgets/post_card.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_event.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_state.dart';

enum FeedType { all, myBlog, liked }

enum SortType { date, likes, comments }

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  FeedType _selectedFeed = FeedType.all;
  SortType _selectedSort = SortType.date;
  String? avatar;
  final ScrollController _scrollController = ScrollController();
  final userStorage = getIt<AuthRemoteDataSource>();

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final info = await userStorage.getAuthInfo();
    final employeeJson = info['employee'] as Map<String, dynamic>?;
    setState(() {
      avatar = employeeJson?['photoPath'];
    });
    _load();
  }

  void _load() {
    context.read<BlogBloc>().add(
      LoadBlogPosts(
        feedType: _selectedFeed,
        sortType: _selectedSort,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      ),
    );
  }

  String _titleForFeed(FeedType type) {
    switch (type) {
      case FeedType.all:
        return 'Вся лента';
      case FeedType.myBlog:
        return 'Мой блог';
      case FeedType.liked:
        return 'Понравившиеся посты';
    }
  }

  PopupMenuItem<SortType> _buildSortItem(SortType value, String title) {
    final isSelected = _selectedSort == value;
    return PopupMenuItem(
      value: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.pop(context);
          setState(() {
            _selectedSort = value;
            _load();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? const Color(AppColors.primary)
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<FeedType> _buildFeedItem(FeedType value, String title) {
    final isSelected = _selectedFeed == value;
    return PopupMenuItem(
      value: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.pop(context);
          setState(() {
            _selectedFeed = value;
            _load();
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: isSelected
                    ? const Color(AppColors.primary)
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOrTitle() {
    if (_isSearching) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              hintText: 'Поиск...',
              hintStyle: TextStyle(color: Colors.black87),
              border: InputBorder.none,
              isDense: true,
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                setState(() {
                  _searchQuery = value;
                });
                _load();
              });
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: PopupMenuButton<FeedType>(
        color: Color(AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          _buildFeedItem(FeedType.all, 'Вся лента'),
          _buildFeedItem(FeedType.myBlog, 'Мой блог'),
          _buildFeedItem(FeedType.liked, 'Понравившиеся посты'),
        ],
        offset: const Offset(0, 40),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                _titleForFeed(_selectedFeed),
                style: AppStyle.manrope(
                  size: 25,
                  weight: FontWeight.w600,
                  color: Color(AppColors.black),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(AppColors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lightBg = Color(0xFFF9FAFA);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        backgroundColor: const Color(AppColors.background),
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: _buildSearchOrTitle(),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Color(AppColors.grey)),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
                _load();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: Color(AppColors.grey)),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          PopupMenuButton<SortType>(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: const Icon(Icons.filter_list, color: Color(AppColors.grey)),
            itemBuilder: (context) => [
              _buildSortItem(SortType.date, 'По дате публикации'),
              _buildSortItem(SortType.likes, 'По количеству лайков'),
              _buildSortItem(SortType.comments, 'По количеству комментариев'),
            ],
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          color: lightBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  );
                  if (result == true) _load();
                },
                child: SizedBox(
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white, // кнопка белая
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(AppColors.greyLight)),
                    ),
                    child: Center(
                      child: Text(
                        '+ Создать пост',
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w500,
                          color: Color(AppColors.comfPayment),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<BlogBloc, BlogState>(
                builder: (context, state) {
                  if (state is BlogLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is BlogError) {
                    return Center(child: Text('Ошибка: ${state.message}'));
                  }
                  if (state is BlogLoaded) {
                    final posts = state.posts.items ?? [];
                    if (posts.isEmpty) {
                      return const Center(child: Text('Нет постов'));
                    }
                    return Refresher(
                      onRefresh: () async => _load(),
                      content: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return PostCard(
                            id: post.id,
                            authorId: post.authorId,
                            author: post.authorName ?? 'Неизвестный',
                            timeAgo: DateFormat(
                              'dd.MM.yyyy HH:mm',
                            ).format(post.createdAt),
                            text: post.content ?? '',
                            imageUrls: post.imageUrls ?? [],
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
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        shape: const CircleBorder(
          side: BorderSide(color: Color(AppColors.greyLight)),
        ),
        backgroundColor: Colors.white, // белая кнопка
        child: const Icon(
          Icons.arrow_upward,
          color: Color(AppColors.greyLight),
        ),
      ),
    );
  }
}

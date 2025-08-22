import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/helpers.dart';
import 'package:waypay/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay/features/blog/presentation/screens/blog_profile_screen.dart';
import 'package:waypay/features/blog/presentation/widgets/image_modal_viewer.dart';

class PostCard extends StatefulWidget {
  final int id;
  final String author;
  final int authorId;
  final String timeAgo;
  final String text;

  /// Если у поста одно изображение
  final String? imageUrl;

  /// Если у поста несколько изображений
  final List<String> imageUrls;

  final String? fileName;
  final String? fileSize;
  final String? fileThumbnail;
  final bool? isAuthor;
  final String? authorAvatarPath;
  final int likes;
  final int comments;
  final bool isLiked;
  final VoidCallback onLikePressed;
  final VoidCallback? onCommentsPressed;
  final VoidCallback? onChanged;

  const PostCard({
    super.key,
    required this.id,
    required this.author,
    required this.authorId,
    required this.timeAgo,
    required this.text,
    this.imageUrl,
    this.imageUrls = const [],
    this.fileName,
    this.fileSize,
    this.fileThumbnail,
    this.authorAvatarPath,
    this.isAuthor,
    this.onChanged,
    required this.likes,
    required this.comments,
    required this.isLiked,
    this.onLikePressed = _noop,
    this.onCommentsPressed,
  });

  static void _noop() {}

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final BlogRemoteDataSources _blogDataSource = getIt<BlogRemoteDataSources>();

  String _resolveUrl(String? url, {bool isAvatar = false}) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('/')) {
      return isAvatar ? 'http://test.waypay.one:5000$url' : 'http://test.waypay.one:5003$url';
    }
    return url;
  }

  Future<void> _deletePost() async {
    final confirmed = await showConfirmDialog(context: context);
    if (confirmed) {
      try {
        await _blogDataSource.deletePost(widget.id);
        if (mounted && widget.onChanged != null) {
          widget.onChanged!();
        }
      } catch (e) {
        if (!mounted) return;
        showMessage('Ошибка при удалении: $e', context);
      }
    }
  }

  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'delete') _deletePost();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.pop(context);
              _deletePost();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.black87),
                  SizedBox(width: 4),
                  Text('Удалить'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Список урлов (с учётом одиночного imageUrl)
    final List<String> rawUrls = widget.imageUrls.isNotEmpty
        ? widget.imageUrls
        : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
        ? [widget.imageUrl!]
        : const [];

    final List<String> resolvedUrls = rawUrls.map((u) => _resolveUrl(u)).where((u) => u.isNotEmpty).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(AppColors.greyLight), width: 1.0),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Автор
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileBlogScreen(id: widget.authorId)),
                    );
                  },
                  child: buildAvatar(photoPath: widget.authorAvatarPath, fullName: widget.author, radius: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.author, style: AppStyle.manrope(size: 14, weight: FontWeight.w600)),
                      Text(widget.timeAgo, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
                    ],
                  ),
                ),
                if (widget.isAuthor == true) _buildMenu(context),
              ],
            ),
            const SizedBox(height: 8),

            // Текст
            if (widget.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(widget.text, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
              ),

            // Медиа (с кэшем + префетч)
            if (resolvedUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ImagesBlockCached(urls: resolvedUrls, onTapImage: (url) => ImageModalViewer.show(context, url)),
              ),

            // Файл (если есть)
            if (widget.fileName != null && widget.fileThumbnail != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_resolveUrl(widget.fileThumbnail), width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.fileName}\n${widget.fileSize ?? ''}',
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Действия
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: widget.onLikePressed,
                  child: Row(
                    children: [
                      Icon(
                        widget.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: widget.isLiked ? const Color(AppColors.red) : const Color(AppColors.darkGrey),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.likes}',
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w400,
                          color: const Color(AppColors.darkGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCommentsPressed,
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20, color: Color(AppColors.darkGrey)),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.comments}',
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w400,
                          color: const Color(AppColors.darkGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.share, size: 20, color: Color(AppColors.darkGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Блок изображений с кэшированием и префетчем соседних.
/// ВАЖНО: лениво создаём CacheManager и префетчим в didChangeDependencies,
/// чтобы не ловить ошибки channel/path_provider и MediaQuery в initState.
class _ImagesBlockCached extends StatefulWidget {
  final List<String> urls;
  final void Function(String url)? onTapImage;

  const _ImagesBlockCached({required this.urls, this.onTapImage});

  @override
  State<_ImagesBlockCached> createState() => _ImagesBlockCachedState();
}

class _ImagesBlockCachedState extends State<_ImagesBlockCached> {
  final PageController _controller = PageController(keepPage: true);
  int _index = 0;

  late final CacheManager _mediaCache;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _mediaCache = CacheManager(Config('postMediaCache', stalePeriod: Duration(days: 14), maxNrOfCacheObjects: 300));
      // первичный префетч — безопасно здесь
      _prefetch(_index);
      _prefetch(_index + 1);
      _initialized = true;
    }
  }

  void _prefetch(int i) {
    if (i < 0 || i >= widget.urls.length) return;
    final provider = CachedNetworkImageProvider(widget.urls[i], cacheKey: widget.urls[i], cacheManager: _mediaCache);
    precacheImage(provider, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCachedImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: url,
      cacheManager: _mediaCache,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 80),
      placeholder: (_, __) => Container(color: Colors.black12),
      errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      useOldImageOnUrlChange: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.length == 1) {
      final url = widget.urls.first;
      return GestureDetector(
        onTap: () => widget.onTapImage?.call(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(aspectRatio: 4 / 3, child: _buildCachedImage(url)),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _prefetch(i - 1);
                _prefetch(i + 1);
              },
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => widget.onTapImage?.call(widget.urls[i]),
                child: _buildCachedImage(widget.urls[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Индикаторы
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.urls.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 18 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? Colors.teal : Colors.teal.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

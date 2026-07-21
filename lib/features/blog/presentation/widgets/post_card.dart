import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/features/blog/data/data_sources/blog_remote_data_sources.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/blog_profile_screen.dart';
import 'package:waypay_mobile/features/blog/presentation/widgets/image_modal_viewer.dart';
import 'package:waypay_mobile/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/models/chat/chat_response.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class PostCard extends StatefulWidget {
  final int id;
  final String author;
  final int authorId;
  final String timeAgo;
  final String text;

  final String? imageUrl;
  final bool? isChat;
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
    this.isChat,
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
      return isAvatar
          ? '${ApiConfig.apiBaseUrl}$url'
          : '${ApiConfig.filesBaseUrl}$url';
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
    final List<String> rawUrls = widget.imageUrls.isNotEmpty
        ? widget.imageUrls
        : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
        ? [widget.imageUrl!]
        : const [];

    final List<String> resolvedUrls = rawUrls
        .map((u) => _resolveUrl(u))
        .where((u) => u.isNotEmpty)
        .toList();

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileBlogScreen(id: widget.authorId),
                      ),
                    );
                  },
                  child: buildAvatar(
                    photoPath: widget.authorAvatarPath,
                    fullName: widget.author,
                    radius: widget.isChat == null ? 20 : 15,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileBlogScreen(id: widget.authorId),
                            ),
                          );
                        },
                        child: Text(
                          widget.author,
                          style: AppStyle.manrope(
                            size: widget.isChat == null ? 14 : 11,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        widget.timeAgo,
                        style: AppStyle.manrope(
                          size: widget.isChat == null ? 14 : 11,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isAuthor == true && widget.isChat == null)
                  _buildMenu(context),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.text,
                  style: AppStyle.manrope(
                    size: widget.isChat == null ? 14 : 11,
                    weight: FontWeight.w400,
                  ),
                ),
              ),
            if (resolvedUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ImagesBlockCached(
                  urls: resolvedUrls,
                  onTapImage: (url) => ImageModalViewer.show(context, url),
                ),
              ),

            if (widget.fileName != null && widget.fileThumbnail != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _resolveUrl(widget.fileThumbnail),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        memCacheWidth: 100,
                        memCacheHeight: 100,
                      ),
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
                        color: widget.isLiked
                            ? const Color(AppColors.red)
                            : const Color(AppColors.uiBorder),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.likes}',
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w400,
                          color: const Color(AppColors.uiBorder),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCommentsPressed,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Color(AppColors.uiBorder),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.comments}',
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w400,
                          color: const Color(AppColors.uiBorder),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isChat == null)
                  GestureDetector(
                    onTap: () async {
                      final ok = await showSharePostDialog(
                        context,
                        postId: widget.id,
                      );
                      if (ok == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пост отправлен')),
                        );
                      }
                    },
                    child: const Icon(
                      Icons.share,
                      size: 20,
                      color: Color(AppColors.uiBorder),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
      _mediaCache = CacheManager(
        Config(
          'postMediaCache',
          stalePeriod: Duration(days: 14),
          maxNrOfCacheObjects: 300,
        ),
      );

      _prefetch(_index);
      _prefetch(_index + 1);
      _initialized = true;
    }
  }

  void _prefetch(int i) {
    if (i < 0 || i >= widget.urls.length) return;
    final provider = CachedNetworkImageProvider(
      widget.urls[i],
      cacheKey: widget.urls[i],
      cacheManager: _mediaCache,
    );
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
      errorWidget: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
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
                color: active
                    ? Colors.teal
                    : Colors.teal.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

Future<bool?> showSharePostDialog(BuildContext context, {required int postId}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SharePostDialog(postId: postId),
  );
}

class _SharePostDialog extends StatefulWidget {
  final int postId;
  const _SharePostDialog({required this.postId});

  @override
  State<_SharePostDialog> createState() => _SharePostDialogState();
}

class _SharePostDialogState extends State<_SharePostDialog> {
  final _msgCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _selected = <int>{};

  late final ChatRemoteDataSource _chatApi = getIt<ChatRemoteDataSource>();
  late final MessageRemoteDataSource _msgApi = getIt<MessageRemoteDataSource>();

  List<ChatResponse> _filtered = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadChats({String? q}) async {
    setState(() => _loading = true);
    try {
      final data = await _chatApi.getMyChats(search: q);
      setState(() {
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось загрузить чаты: $e')));
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = _searchCtrl.text.trim();

      await _loadChats(q: q.isEmpty ? null : q);
    });
  }

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);

    try {
      final msg = _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim();
      for (final chatId in _selected) {
        await _msgApi.sendMessage(
          chatId,
          text: msg,
          postId: widget.postId,
          attachments: const [],
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
    }
  }

  Widget _chatTile(ChatResponse c) {
    final checked = _selected.contains(c.id);
    return InkWell(
      onTap: () {
        setState(() {
          if (checked) {
            _selected.remove(c.id);
          } else {
            _selected.add(c.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: (_) {
                setState(() {
                  if (checked) {
                    _selected.remove(c.id);
                  } else {
                    _selected.add(c.id);
                  }
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            buildAvatar(
              fullName: c.name ?? 'Чат',
              radius: 18,
              photoPath: c.avatarPath,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name ?? 'Чат ${c.id}',
                    style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    c.lastMessage?.text?.trim().isNotEmpty == true
                        ? (c.lastMessage!.text!.length > 40
                              ? '${c.lastMessage!.text!.substring(0, 40)}…'
                              : c.lastMessage!.text!)
                        : 'Нет сообщений',
                    style: AppStyle.manrope(
                      size: 13,
                      weight: FontWeight.w400,
                      color: const Color(AppColors.uiBorder),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _selected.isNotEmpty && !_sending;

    return Dialog(
      backgroundColor: Color(AppColors.background),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          minWidth: 340,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Поделиться постом',
                    style: AppStyle.manrope(size: 18, weight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _msgCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Добавьте сообщение к посту (необязательно)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Поиск чатов...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _filtered.isEmpty
                          ? const Center(child: Text('Чатов не найдено'))
                          : ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (_, i) => _chatTile(_filtered[i]),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selected.isEmpty
                          ? 'Выберите чаты для отправки'
                          : 'Выбрано чатов: ${_selected.length}',
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w400,
                        color: const Color(AppColors.uiBorder),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: canSend ? _send : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.primary),
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Отправить'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

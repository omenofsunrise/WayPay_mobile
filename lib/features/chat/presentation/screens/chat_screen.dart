import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';

import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_event.dart';
import 'package:waypay_mobile/features/blog/presentation/bloc/blog_state.dart';
import 'package:waypay_mobile/features/blog/presentation/screens/comments_screen.dart';
import 'package:waypay_mobile/features/blog/presentation/widgets/post_card.dart';
import 'package:waypay_mobile/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/service/chat_hub_service.dart';
import 'package:waypay_mobile/features/chat/data/models/message/message_response.dart';
import 'package:waypay_mobile/features/chat/data/models/message/message_attachment_response.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'package:waypay_mobile/features/chat/presentation/screens/chat_info_screen.dart';
import 'package:waypay_mobile/features/chat/presentation/widgets/chat_text_field.dart';
import 'package:waypay_mobile/features/chat/presentation/widgets/telegram_link_preview.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/task_action_dropdown.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final bool isGroup;
  final String? chatName;
  final String? chatAvatarPath;
  final VoidCallback? onChatUpdated;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.isGroup,
    this.chatName,
    this.chatAvatarPath,
    this.onChatUpdated,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<MultipartFile> _attachments = [];
  final List<File> _localFiles = [];
  final AuthRemoteDataSource dataSource = getIt<AuthRemoteDataSource>();
  Employee? _currentEmployee;
  final _imagePicker = ImagePicker();
  final _timeFmt = DateFormat('HH:mm');

  bool _showScrollDownBtn = false;
  Timer? _typingDebounce;

  late final ChatBloc _chatBloc;
  late final BlogBloc _blogBloc;
  int? _editingMessageId;
  bool get _isEditing => _editingMessageId != null;

  static const String _filesBase = ApiConfig.filesBaseUrl;

  @override
  void initState() {
    super.initState();
    _blogBloc = BlogBloc();
    _chatBloc = ChatBloc(
      messageApi: getIt<MessageRemoteDataSource>(),
      hub: getIt<ChatHubService>(),
      chatId: widget.chatId,
      chatApi: getIt<ChatRemoteDataSource>(),
    );
    _chatBloc
      ..add(const ChatStarted())
      ..add(const ChatMembersRequested());
    _loadEmployee();
    _scrollController.addListener(_onScroll);

    _chatController.addListener(() {
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        context.read<ChatBloc>().add(const ChatTyping());
      });
    });
  }

  Future<void> _loadEmployee() async {
    final info = await dataSource.getAuthInfo();
    final employeeJson = info['employee'] as Map<String, dynamic>?;
    setState(() {
      _currentEmployee = employeeJson != null
          ? Employee.fromJson(employeeJson)
          : null;
    });
  }

  @override
  void dispose() {
    _chatBloc.close();
    _blogBloc.close();
    _typingDebounce?.cancel();
    _scrollController.dispose();
    _chatController.dispose();
    _focusNode.dispose();
    widget.onChatUpdated?.call();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isNotAtBottom = _scrollController.position.pixels > 300;
    if (_showScrollDownBtn == isNotAtBottom) return;
    setState(() {
      _showScrollDownBtn = isNotAtBottom;
    });
  }

  // ===== helpers =====

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$_filesBase$url';
    return '$_filesBase/$url';
  }

  String _ext(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  bool _isImageCt(String? ct) =>
      ct != null && ct.toLowerCase().startsWith('image/');
  bool _isVideoCt(String? ct) =>
      ct != null && ct.toLowerCase().startsWith('video/');
  bool _isImageName(String v) => RegExp(
    r'\.(png|jpe?g|gif|webp|heic|heif)$',
    caseSensitive: false,
  ).hasMatch(v);
  bool _isVideoName(String v) => RegExp(
    r'\.(mp4|mov|avi|mkv|webm|m4v)$',
    caseSensitive: false,
  ).hasMatch(v);

  Future<Uint8List?> _thumbFromLocalVideo(File file) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 70,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _thumbFromVideoUrl(String url) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      return await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 70,
      );
    } catch (_) {
      return null;
    }
  }

  Future<MultipartFile> _multipartForFile({
    required File file,
    required String filename,
    MediaType? contentType,
  }) async {
    int size = 0;
    try {
      size = await file.length();
    } catch (_) {
      size = 0;
    }

    if (size == 0) {
      return MultipartFile.fromBytes(
        const <int>[],
        filename: filename,
        contentType: contentType ?? MediaType('application', 'octet-stream'),
      );
    } else {
      return MultipartFile.fromFile(
        file.path,
        filename: filename,
        contentType: contentType,
      );
    }
  }

  // ===== pickers =====

  Future<void> _pickMedia() async {
    final XFile? picked = await _imagePicker.pickMedia(imageQuality: 80);
    if (picked == null) return;

    final file = File(picked.path);
    final ext = _ext(file.path).toLowerCase();

    MediaType contentType;
    if (_isImageName(file.path)) {
      final subtype = (ext == 'jpg') ? 'jpeg' : (ext.isEmpty ? 'jpeg' : ext);
      contentType = MediaType('image', subtype);
    } else if (_isVideoName(file.path)) {
      switch (ext) {
        case 'mp4':
          contentType = MediaType('video', 'mp4');
          break;
        case 'mov':
          contentType = MediaType('video', 'quicktime');
          break;
        case 'avi':
          contentType = MediaType('video', 'x-msvideo');
          break;
        case 'mkv':
          contentType = MediaType('video', 'x-matroska');
          break;
        case 'webm':
          contentType = MediaType('video', 'webm');
          break;
        default:
          contentType = MediaType('video', ext);
      }
    } else {
      contentType = MediaType('application', 'octet-stream');
    }

    final multipart = await _multipartForFile(
      file: file,
      filename: file.path.split('/').last,
      contentType: contentType,
    );

    setState(() {
      _attachments.add(multipart);
      _localFiles.add(file);
    });
  }

  Future<void> _pickFile() async {
    const videoExts = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'];
    const docExts = [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'txt',
      'csv',
    ];
    const archExts = ['zip', 'rar', '7z', 'tar', 'gz'];
    final allowed = [...videoExts, ...docExts, ...archExts];

    final result = await FilePicker.platform.pickFiles(
      withData: false,
      type: FileType.custom,
      allowedExtensions: allowed,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final name = file.path.split('/').last;
    final ext = _ext(name);

    MediaType contentType;
    if (videoExts.contains(ext)) {
      switch (ext) {
        case 'mp4':
          contentType = MediaType('video', 'mp4');
          break;
        case 'mov':
          contentType = MediaType('video', 'quicktime');
          break;
        case 'avi':
          contentType = MediaType('video', 'x-msvideo');
          break;
        case 'mkv':
          contentType = MediaType('video', 'x-matroska');
          break;
        case 'webm':
          contentType = MediaType('video', 'webm');
          break;
        case 'm4v':
          contentType = MediaType('video', 'x-m4v');
          break;
        default:
          contentType = MediaType('video', ext);
      }
    } else if (docExts.contains(ext)) {
      switch (ext) {
        case 'pdf':
          contentType = MediaType('application', 'pdf');
          break;
        case 'doc':
          contentType = MediaType('application', 'msword');
          break;
        case 'docx':
          contentType = MediaType(
            'application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document',
          );
          break;
        case 'xls':
          contentType = MediaType('application', 'vnd.ms-excel');
          break;
        case 'xlsx':
          contentType = MediaType(
            'application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          break;
        case 'ppt':
          contentType = MediaType('application', 'vnd.ms-powerpoint');
          break;
        case 'pptx':
          contentType = MediaType(
            'application',
            'vnd.openxmlformats-officedocument.presentationml.presentation',
          );
          break;
        case 'txt':
          contentType = MediaType('text', 'plain');
          break;
        case 'csv':
          contentType = MediaType('text', 'csv');
          break;
        default:
          contentType = MediaType('application', 'octet-stream');
      }
    } else if (archExts.contains(ext)) {
      contentType = MediaType('application', 'octet-stream');
    } else {
      contentType = MediaType('application', 'octet-stream');
    }

    final multipart = await _multipartForFile(
      file: file,
      filename: name,
      contentType: contentType,
    );

    setState(() {
      _attachments.add(multipart);
      _localFiles.add(file);
    });
  }

  // ===== fullscreen viewers =====

  Future<void> _openUrlFullscreenImage(String url) async {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          alignment: Alignment.center,
          color: Colors.black,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openVideoPlayer(String url) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/${url.split('/').last}';

    if (!File(filePath).existsSync()) {
      await Dio().download(_resolveUrl(url), filePath);
    }

    final controller = VideoPlayerController.file(File(filePath));
    await controller.initialize();

    final chewie = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.white,
        handleColor: Colors.white,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white54,
      ),
    );

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 16 / 9
                : controller.value.aspectRatio,
            child: Chewie(controller: chewie),
          ),
        ),
      ),
    );

    await chewie.pause();
    await controller.pause();
    chewie.dispose();
    await controller.dispose();
  }

  // ===== send =====

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    if (_isEditing) {
      _chatBloc.add(ChatEditConfirm(id: _editingMessageId!, newText: text));
    } else {
      _chatBloc.add(
        ChatSend(
          text: text.isEmpty ? null : text,
          attachments: List<MultipartFile>.from(_attachments),
        ),
      );
    }

    _chatController.clear();
    setState(() {
      _attachments.clear();
      _localFiles.clear();
      _editingMessageId = null;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ===== preview before send =====

  Widget _attachmentsPreview() {
    if (_attachments.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _attachments.length,
        itemBuilder: (context, i) {
          final fileName = _attachments[i].filename ?? 'file';
          final lower = fileName.toLowerCase();
          final isImage = _isImageName(lower);
          final isVideo = _isVideoName(lower);

          Widget thumb;
          if (isImage && i < _localFiles.length) {
            thumb = ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_localFiles[i], fit: BoxFit.cover),
            );
          } else if (isVideo && i < _localFiles.length) {
            thumb = FutureBuilder<Uint8List?>(
              future: _thumbFromLocalVideo(_localFiles[i]),
              builder: (context, snap) {
                final bytes = snap.data;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: bytes != null
                          ? Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                            )
                          : Container(
                              color: Colors.black12,
                              width: 60,
                              height: 60,
                            ),
                    ),
                    const Icon(
                      Icons.play_circle_fill,
                      size: 26,
                      color: Colors.white70,
                    ),
                  ],
                );
              },
            );
          } else {
            thumb = const Icon(Icons.insert_drive_file);
          }

          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: thumb,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _attachments.removeAt(i);
                    if (i < _localFiles.length) _localFiles.removeAt(i);
                  });
                },
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _linkPreview(String url) => TelegramLinkPreview(url: url);

  // ===== render message =====

  Widget _messageAttachments(
    List<MessageAttachmentResponse> atts,
    int? postId,
  ) {
    if (atts.isEmpty && postId == null) return const SizedBox.shrink();
    if (postId != null) {
      return BlocProvider(
        create: (context) => BlogBloc()..add(LoadBlogPostById(postId)),
        child: BlocBuilder<BlogBloc, BlogState>(
          builder: (context, state) {
            if (state is BlogLoading) {
              return const SizedBox(
                width: 300,
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is BlogError) {
              return SizedBox(
                width: 300,
                height: 300,
                child: Center(child: Text('Ошибка: ${state.message}')),
              );
            }

            if (state is BlogPostLoaded) {
              final post = state.post;
              return PostCard(
                id: post.id,
                isChat: true,
                author: post.authorName ?? '',
                authorId: post.authorId,
                timeAgo: DateFormat('dd.MM.yyyy HH:mm').format(post.createdAt),
                text: post.content ?? '',
                imageUrls: post.imageUrls ?? [],
                authorAvatarPath: post.authorAvatarPath,
                likes: post.likesCount,
                comments: post.commentsCount,
                isLiked: post.isLikedByCurrentUser,
                isAuthor: post.isAuthor,
                onLikePressed: () {
                  _blogBloc.add(ToggleLikeChatPost(post.id));
                },
                onCommentsPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(
                        postId: post.id,
                        isAuthor: post.isAuthor,
                      ),
                    ),
                  );

                  if (updated == true) {
                    _blogBloc.add(LoadBlogPostById(post.id));
                  }
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      );
    }

    final tiles = atts.map((att) {
      final raw = att.fileUrl;
      final url = _resolveUrl(raw);
      final name = att.fileName ?? (url.split('/').last);
      final ct = att.contentType;

      final isImg = _isImageCt(ct) || _isImageName(name) || _isImageName(url);
      final isVid = _isVideoCt(ct) || _isVideoName(name) || _isVideoName(url);

      if (isImg) {
        return GestureDetector(
          onTap: () => _openUrlFullscreenImage(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 220,
                height: 220,
                color: Colors.black12,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image, color: Colors.black54),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(name, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      if (isVid) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openVideoPlayer(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: FutureBuilder<Uint8List?>(
                      future: _thumbFromVideoUrl(url),
                      builder: (context, snap) {
                        final bytes = snap.data;
                        if (bytes != null)
                          return Image.memory(bytes, fit: BoxFit.cover);
                        return Container(color: Colors.black12);
                      },
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    size: 64,
                    color: Colors.white70,
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return InkWell(
        onTap: url.isEmpty ? null : () => _downloadAndOpenFile(url, name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.insert_drive_file,
                size: 18,
                color: Colors.black54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 8, runSpacing: 8, children: tiles),
    );
  }

  Future<void> _downloadAndOpenFile(String url, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final response = await Dio().download(url, filePath);

      if (response.statusCode == 200) {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          if (!mounted) return;
          showMessage('Не удалось открыть файл: ${result.message}', context);
        }
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      showMessage('Ошибка при загрузке или открытии файла', context);
    }
  }

  // ===== delete chat (menu action) =====

  Future<void> _confirmAndDeleteChat() async {
    // подтверждение
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(AppColors.background),
        title: const Text('Удалить чат?'),
        content: const Text(
          'Вы действительно хотите удалить этот приватный чат?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // прогресс
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await getIt<ChatRemoteDataSource>().deletePrivateChat(widget.chatId);
      if (!mounted) return;
      Navigator.of(context).pop(); // закрыть прогресс
      widget.onChatUpdated?.call();
      Navigator.of(context).pop(true); // закрыть экран чата -> список обновится
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // закрыть прогресс
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось удалить чат: $e')));
    }
  }

  // ===== bubble =====

  Widget _bubble(
    MessageResponse m,
    int index,
    List<MessageResponse> messages,
    ChatBloc chatBloc, {
    Key? key,
  }) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.8;
    final time = _timeFmt.format(m.sentAt.toLocal());
    final isMe = _currentEmployee?.id == m.sender!.id;

    final isFirstInSequence =
        index == messages.length - 1 ||
        messages[index + 1].sender!.id != m.sender!.id;
    final isLastInSequence =
        index == 0 || messages[index - 1].sender!.id != m.sender!.id;

    final List<MessageAttachmentResponse> atts = (m.attachments ?? [])
        .map((e) => MessageAttachmentResponse.fromJson(e.toJson()))
        .toList();

    String? urlFromText;
    if (m.text != null && m.text!.isNotEmpty) {
      final regex = RegExp(r'(https?:\/\/[^\s]+)');
      final match = regex.firstMatch(m.text!);
      if (match != null) urlFromText = match.group(0);
    }

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe && widget.isGroup)
            isLastInSequence
                ? GestureDetector(
                    onTap: () async {
                      final chatApi = getIt<ChatRemoteDataSource>();
                      try {
                        final chat = await chatApi.getOrCreatePrivate(
                          m.sender!.id,
                        );
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => ChatBloc(
                                messageApi: getIt<MessageRemoteDataSource>(),
                                hub: getIt<ChatHubService>(),
                                chatId: chat.id,
                                chatApi: chatApi,
                              )..add(const ChatStarted()),
                              child: ChatScreen(
                                chatId: chat.id,
                                isGroup: chat.type != 'private_chat',
                                chatName: chat.name,
                                chatAvatarPath: chat.avatarPath,
                                onChatUpdated: () {
                                  context.read<ChatListBloc>().add(
                                    const ChatListRefreshed(),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        showMessage('Ошибка при открытии чата: $e', context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: buildAvatar(
                        fullName: m.sender!.fullName ?? '',
                        radius: 20,
                        photoPath: m.sender!.photoPath,
                      ),
                    ),
                  )
                : const SizedBox(width: 48),
          GestureDetector(
            onLongPressStart: isMe
                ? (details) async {
                    final action = await showMenu<TaskAction>(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                      ),
                      items: [
                        PopupMenuItem(
                          value: TaskAction.edit,
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Изменить",
                                style: AppStyle.manrope(
                                  size: 14,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: TaskAction.delete,
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Удалить",
                                style: AppStyle.manrope(
                                  size: 14,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    if (action == TaskAction.delete) {
                      if (!mounted) return;
                      chatBloc.add(ChatDelete(id: m.id));
                    } else if (action == TaskAction.edit) {
                      if (!mounted) return;
                      setState(() {
                        _editingMessageId = m.id;
                        _attachments.clear();
                        _localFiles.clear();
                        _chatController.text = m.text ?? '';
                        _chatController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _chatController.text.length),
                        );
                      });
                      FocusScope.of(context).requestFocus(_focusNode);
                    }
                  }
                : null,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(AppColors.selfChatBubble)
                    : const Color(AppColors.chatBubble),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    isMe ? 10 : (isFirstInSequence ? 10 : 4),
                  ),
                  topRight: Radius.circular(
                    !isMe ? 10 : (isFirstInSequence ? 10 : 4),
                  ),
                  bottomLeft: Radius.circular(
                    isMe ? 10 : (isLastInSequence ? 10 : 4),
                  ),
                  bottomRight: Radius.circular(
                    isMe ? (isLastInSequence ? 10 : 4) : 12,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((m.text ?? '').isNotEmpty)
                    Text(
                      m.text!,
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  if (urlFromText != null) _linkPreview(urlFromText),
                  _messageAttachments(atts, m.postId),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      time,
                      style: AppStyle.manrope(
                        size: 12,
                        weight: FontWeight.w400,
                        color: const Color(AppColors.darkGrey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _membersTitle(int count) {
    final n = count % 100;
    if (n >= 11 && n <= 14) return '$count участников';
    switch (count % 10) {
      case 1:
        return '$count участник';
      case 2:
      case 3:
      case 4:
        return '$count участника';
      default:
        return '$count участников';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onChatUpdated?.call();
        return true;
      },
      child: BlocProvider.value(
        value: _chatBloc,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(AppColors.lightGreyBackground),
          appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            backgroundColor: Color(AppColors.background),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop(true);
                widget.onChatUpdated?.call();
              },
            ),
            iconTheme: const IconThemeData(color: Color(AppColors.darkGrey)),
            // 🔻 убрали поиск, оставили меню с «Удалить чат»
            actions: [
              if (!widget.isGroup)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await _confirmAndDeleteChat();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Удалить чат'),
                    ),
                  ],
                ),
            ],
            title: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatInfoScreen(
                          isGroup: widget.isGroup,
                          chanName: widget.chatName!,
                          avatarPath: widget.chatAvatarPath,
                          id: widget.chatId,
                          membersCount: _membersTitle(state.members.length),
                          empId: (state.members.length > 1)
                              ? (_currentEmployee!.id != state.members[1].id
                                    ? state.members[1].id
                                    : state.members[0].id)
                              : (_currentEmployee?.id),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      buildAvatar(
                        fullName:
                            widget.chatName ??
                            (widget.isGroup ? 'Групповой чат' : 'Чат'),
                        radius: 20,
                        photoPath: widget.chatAvatarPath,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.chatName ??
                                  (widget.isGroup ? 'Групповой чат' : 'Чат'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyle.manrope(
                                size: 16,
                                weight: FontWeight.w400,
                              ),
                            ),
                            if (widget.isGroup)
                              Text(
                                state.isMembersLoading
                                    ? 'Загружаем участников…'
                                    : _membersTitle(state.members.length),
                                style: AppStyle.manrope(
                                  size: 12,
                                  weight: FontWeight.w400,
                                  color: const Color(AppColors.darkGrey),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          body: Stack(
            children: [
              BlocBuilder<ChatBloc, ChatState>(
                builder: (_, s) {
                  if (s.isLoading && s.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (s.error != null && s.messages.isEmpty) {
                    return Center(child: Text('Ошибка: ${s.error}'));
                  }

                  final msgs = s.messages;
                  return NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification &&
                          _scrollController.position.pixels <=
                              _scrollController.position.minScrollExtent +
                                  200) {
                        context.read<ChatBloc>().add(ChatLoadMore());
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 80, top: 12),
                      itemCount: msgs.length + (s.isPaging ? 1 : 0),
                      reverse: true,
                      itemBuilder: (context, index) {
                        if (index == 0 && s.isPaging) {
                          return const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final m = s.messages[s.isPaging ? index - 1 : index];
                        return _bubble(
                          m,
                          index,
                          msgs,
                          _chatBloc,
                          key: ValueKey(m.id),
                        );
                      },
                    ),
                  );
                },
              ),
              if (_showScrollDownBtn)
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingActionButton(
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
                    backgroundColor: Color(AppColors.background),
                    child: const Icon(
                      Icons.arrow_downward,
                      color: Color(AppColors.greyLight),
                    ),
                  ),
                ),
            ],
          ),
          bottomSheet: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isEditing) ...[],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _attachmentsPreview(),
                ),
                ChatTextField(
                  controller: _chatController,
                  focusNode: _focusNode,
                  onPickImage: _isEditing ? null : () => _pickMedia(),
                  onPickFile: _isEditing ? null : () => _pickFile(),
                  onSend: _sendMessage,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/features/chat/data/models/chat/chat_response.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat_info/chat_video_bloc.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat_info/paged_bloc.dart';

class VideosTabContent extends StatefulWidget {
  final int chatId;

  const VideosTabContent({super.key, required this.chatId});

  @override
  State<VideosTabContent> createState() => _VideosTabContentState();
}

class _VideosTabContentState extends State<VideosTabContent> {
  late final ChatVideosBloc bloc;
  static const String _filesBase = 'https://web.waypay_mobile.one:5002';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bloc = ChatVideosBloc(chatId: widget.chatId)
      ..add(LoadPage<MessageAttachmentResponse>());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final state = bloc.state;
    if (state is PagedLoaded<MessageAttachmentResponse> && state.hasMore) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        bloc.add(LoadPage<MessageAttachmentResponse>());
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    bloc.close();
    super.dispose();
  }

  Map<String, List<MessageAttachmentResponse>> _groupByMonth(
    List<MessageAttachmentResponse> items,
  ) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];

    final Map<String, List<MessageAttachmentResponse>> grouped = {};
    for (var item in items) {
      final monthName = '${months[item.sentAt.month - 1]} ${item.sentAt.year}';
      grouped.putIfAbsent(monthName, () => []).add(item);
    }
    return grouped;
  }

  Future<Uint8List?> _getVideoThumbnail(String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${url.split('/').last}');

      if (!tempFile.existsSync()) {
        await Dio().download(_resolveUrl(url), tempFile.path);
      }

      final thumbData = await VideoThumbnail.thumbnailData(
        video: tempFile.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 200,
        quality: 75,
      );

      return thumbData;
    } catch (e) {
      return null;
    }
  }

  Widget _buildVideo(MessageAttachmentResponse video) {
    final url = video.fileUrl ?? '';

    return GestureDetector(
      onTap: () => _openVideoPlayer(url),

      child: FutureBuilder<Uint8List?>(
        future: _getVideoThumbnail(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(color: Colors.black12);
          }

          final thumbData = snapshot.data;
          return Stack(
            children: [
              thumbData != null
                  ? Image.memory(
                      thumbData,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Container(color: Colors.grey[300]),
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$_filesBase$url';
    return '$_filesBase/$url';
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ChatVideosBloc, PagedState<MessageAttachmentResponse>>(
        builder: (context, state) {
          List<MessageAttachmentResponse> items = [];
          bool isLoadingMore = false;

          if (state is PagedLoading && (state is! PagedLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PagedError<MessageAttachmentResponse>) {
            return Center(
              child: Text(
                state.message,
                style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
              ),
            );
          }

          if (state is PagedLoaded<MessageAttachmentResponse>) {
            items = state.items;
            isLoadingMore = state.hasMore;
          }

          if (items.isEmpty) {
            return Center(
              child: Text(
                'Нет видео',
                style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
              ),
            );
          }

          final groupedItems = _groupByMonth(items);

          return ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              ...groupedItems.entries.expand((entry) {
                final monthName = entry.key;
                final videos = entry.value;

                return [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      monthName,
                      style: AppStyle.manrope(
                        size: 16,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (MediaQuery.of(context).size.width ~/ 130)
                          .clamp(1, 10),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: videos.length,
                    itemBuilder: (context, index) => Container(
                      color: Colors.grey[300],
                      child: _buildVideo(videos[index]),
                    ),
                  ),
                ];
              }),
              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

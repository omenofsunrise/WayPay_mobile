import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/features/chat/data/models/chat/chat_response.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat_info/chat_photo_bloc.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat_info/paged_bloc.dart';
import 'package:waypay_styles/waypay_styles.dart';

class PhotosTabContent extends StatefulWidget {
  final int chatId;

  const PhotosTabContent({super.key, required this.chatId});

  @override
  State<PhotosTabContent> createState() => _PhotosTabContentState();
}

class _PhotosTabContentState extends State<PhotosTabContent> {
  late final ChatPhotosBloc bloc;
  late final CacheManager _cacheManager;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bloc = ChatPhotosBloc(chatId: widget.chatId)
      ..add(LoadPage<MessageAttachmentResponse>());
    _scrollController.addListener(_onScroll);

    _cacheManager = CacheManager(
      Config(
        'chatPhotosCache',
        stalePeriod: const Duration(days: 14),
        maxNrOfCacheObjects: 500,
      ),
    );
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

  Widget _buildPhoto(BuildContext context, MessageAttachmentResponse photo) {
    if (photo.fileUrl == null || photo.fileUrl!.isEmpty) {
      return const Icon(Icons.image, size: 40, color: Colors.white);
    }

    final src = photo.fileUrl!.startsWith('http')
        ? photo.fileUrl!
        : '${ApiConfig.filesBaseUrl}/${photo.fileUrl!}';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(backgroundColor: Colors.black),
              body: Center(
                child: Hero(
                  tag: src,
                  child: PhotoView(
                    imageProvider: CachedNetworkImageProvider(
                      src,
                      cacheManager: _cacheManager,
                    ),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Hero(
        tag: src,
        child: CachedNetworkImage(
          imageUrl: src,
          cacheManager: _cacheManager,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.black12),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ChatPhotosBloc, PagedState<MessageAttachmentResponse>>(
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
                'Нет фото',
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
                final photos = entry.value;

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
                    itemCount: photos.length,
                    itemBuilder: (context, index) => Container(
                      color: Colors.grey[300],
                      child: _buildPhoto(context, photos[index]),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/chat/data/models/chat/chat_link_response.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_info/paged_bloc.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_info/chat_links_bloc.dart';
import 'package:waypay/features/chat/presentation/widgets/telegram_link_preview.dart';

class LinksTabContent extends StatefulWidget {
  final int chatId;

  const LinksTabContent({super.key, required this.chatId});

  @override
  State<LinksTabContent> createState() => _LinksTabContentState();
}

class _LinksTabContentState extends State<LinksTabContent> {
  late final ChatLinksBloc bloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bloc = ChatLinksBloc(chatId: widget.chatId)
      ..add(LoadPage<ChatLinkResponse>());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final state = bloc.state;
    if (state is PagedLoaded<ChatLinkResponse> && state.hasMore) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        bloc.add(LoadPage<ChatLinkResponse>());
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ChatLinksBloc, PagedState<ChatLinkResponse>>(
        builder: (context, state) {
          if (state is PagedLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PagedError<ChatLinkResponse>) {
            return Center(
              child: Text(
                state.message,
                style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
              ),
            );
          }

          List<ChatLinkResponse> links = [];
          bool isLoadingMore = false;

          if (state is PagedLoaded<ChatLinkResponse>) {
            links = state.items;
            isLoadingMore = state.hasMore;
          }

          if (links.isEmpty) {
            return Center(
              child: Text(
                'Нет ссылок',
                style: AppStyle.manrope(size: 16, weight: FontWeight.w400),
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: links.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= links.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final link = links[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: TelegramLinkPreview(url: link.url ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}

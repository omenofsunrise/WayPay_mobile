import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_styles/waypay_styles.dart';

import 'package:waypay_mobile/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/service/chat_hub_service.dart';

import 'package:waypay_mobile/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';

import 'package:waypay_mobile/features/chat/presentation/screens/chat_screen.dart';
import 'package:waypay_mobile/features/chat/presentation/widgets/chat_tile.dart';

class AllChatScreen extends StatefulWidget {
  const AllChatScreen({super.key});

  @override
  State<AllChatScreen> createState() => _AllChatScreenState();
}

class _AllChatScreenState extends State<AllChatScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      context.read<ChatListBloc>().add(ChatListSearchChanged(text));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatListBloc>()..add(const ChatListStarted()),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SafeArea(
            bottom: false,
            child: Container(
              color: const Color(AppColors.background),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BlocBuilder<ChatListBloc, ChatListState>(
                  builder: (context, state) {
                    final badge = state.totalUnread;
                    return Header(
                      title: 'Чаты',
                      showBackButton: Navigator.canPop(context),
                      showNotifications: false,
                      showAvatar: false,
                      titleWidget: Row(
                        children: [
                          Text(
                            'Чаты',
                            style: AppStyle.semiBold23.copyWith(
                              fontWeight: FontWeight.w500,
                              color: const Color(AppColors.black),
                            ),
                          ),
                          if (badge > 0)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    color: Color(AppColors.background),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$badge',
                                      style: AppStyle.manrope(
                                        size: 14,
                                        weight: FontWeight.w700,
                                        color: Color(AppColors.primary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        body: Container(
          decoration: const BoxDecoration(
            color: Color(AppColors.background),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<ChatListBloc, ChatListState>(
              builder: (context, state) {
                if (state.isLoading && state.chats.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null && state.chats.isEmpty) {
                  return Center(child: Text('Ошибка: ${state.error}'));
                }

                final chats = state.chats;

                return RefreshIndicator(
                  onRefresh: () async => context.read<ChatListBloc>().add(
                    const ChatListRefreshed(),
                  ),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: chats.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade300),
                    itemBuilder: (_, i) {
                      final c = chats[i];
                      final last = c.lastMessage;
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => ChatBloc(
                                  messageApi: getIt<MessageRemoteDataSource>(),
                                  hub: getIt<ChatHubService>(),
                                  chatId: c.id,
                                  chatApi: getIt<ChatRemoteDataSource>(),
                                )..add(const ChatStarted()),
                                child: ChatScreen(
                                  chatId: c.id,
                                  isGroup: c.type != 'private_chat',
                                  chatName: c.name,
                                  chatAvatarPath: c.avatarPath,
                                  onChatUpdated: () {
                                    context.read<ChatListBloc>().add(
                                      const ChatListRefreshed(),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                          if (result == true) {
                            context.read<ChatListBloc>().add(
                              const ChatListRefreshed(),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ChatTile(
                            chatName: c.name ?? 'Чат ${c.id}',
                            avatarPath: c.avatarPath,
                            isUnreaded: (c.unreadCount) > 0,
                            lastMessage: last?.text ?? '',
                            name: last?.sender.fullName ?? '',
                            time:
                                last?.sentAt.toLocal().toString().substring(
                                  11,
                                  16,
                                ) ??
                                '',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

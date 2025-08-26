import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';

import 'package:waypay/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay/features/chat/data/service/chat_hub_service.dart';

import 'package:waypay/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';

import 'package:waypay/features/chat/presentation/screens/chat_screen.dart';
import 'package:waypay/features/chat/presentation/widgets/chat_tile.dart';

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
    // Живой поиск по вводу в контроллер (если изменяем текст программно — тоже сработает)
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

  void _openSearchModal() {
    final tempController = TextEditingController(text: _searchController.text);

    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Поиск',
        backgroundColor: const Color(AppColors.background),
        contentPadding: const EdgeInsets.all(16),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return TextField(
              controller: tempController,
              decoration: InputDecoration(
                hintText: 'Поиск по чатам...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                // Дебаунс для лайв-поиска
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  context.read<ChatListBloc>().add(
                    ChatListSearchChanged(value.trim()),
                  );
                });
              },
            );
          },
        ),
        actions: [
          DefaultButton(
            text: 'Сбросить',
            onPressed: () {
              tempController.clear();
              _searchController.text = '';
              context.read<ChatListBloc>().add(const ChatListStarted());
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          DefaultButton(
            text: 'Применить',
            isGreen: true,
            onPressed: () {
              _searchController.text = tempController.text;
              context.read<ChatListBloc>().add(
                ChatListSearchChanged(_searchController.text.trim()),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatListBloc>()..add(const ChatListStarted()),
      child: Scaffold(
        drawer: const AppDrawer(),

        // зелёная шапка
        backgroundColor: const Color(AppColors.primary),

        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: const Color(AppColors.primary),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: false, // прижимаем заголовок влево
          title: BlocBuilder<ChatListBloc, ChatListState>(
            builder: (context, state) {
              final badge = state.totalUnread;
              return Row(
                children: [
                  Text(
                    'Чаты',
                    style: AppStyle.manrope(
                      size: 25,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (badge > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
              );
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Поиск',
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _openSearchModal,
            ),
            IconButton(
              tooltip: 'Обновить',
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () =>
                  context.read<ChatListBloc>().add(const ChatListRefreshed()),
            ),
          ],
        ),

        // Белый контент с закруглением сверху
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

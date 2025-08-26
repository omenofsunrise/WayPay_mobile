import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/helpers.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay/features/chat/data/service/chat_hub_service.dart';
import 'package:waypay/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_info/chat_member_cubit.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'package:waypay/features/chat/presentation/screens/chat_screen.dart';
import 'package:waypay/features/profile/data/models/employee.dart';

class EmployesTabContent extends StatefulWidget {
  final int chatId;

  const EmployesTabContent({super.key, required this.chatId});

  @override
  State<EmployesTabContent> createState() => _EmployesTabContentState();
}

class _EmployesTabContentState extends State<EmployesTabContent> {
  final AuthRemoteDataSource dataSource = getIt<AuthRemoteDataSource>();
  Employee? _currentEmployee;
  Future<void> _loadEmployee() async {
    final info = await dataSource.getAuthInfo();
    final employeeJson = info['employee'] as Map<String, dynamic>?;
    setState(() {
      _currentEmployee = employeeJson != null ? Employee.fromJson(employeeJson) : null;
    });
  }

  @override
  void initState() {
    _loadEmployee();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatMembersCubit(chatId: widget.chatId)..loadMembers(),
      child: BlocBuilder<ChatMembersCubit, ChatMembersState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Text('Ошибка: ${state.error}', style: AppStyle.manrope(size: 16, weight: FontWeight.w400)),
            );
          }

          if (state.members.isEmpty) {
            return Center(
              child: Text('Нет сотрудников', style: AppStyle.manrope(size: 16, weight: FontWeight.w400)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.members.length,
            itemBuilder: (context, index) {
              final member = state.members[index];

              return GestureDetector(
                onTap: _currentEmployee?.id != member.id
                    ? () async {
                        final chatApi = getIt<ChatRemoteDataSource>();

                        try {
                          final chat = await chatApi.getOrCreatePrivate(member.id);
                          if (!context.mounted) return;
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
                                    context.read<ChatListBloc>().add(const ChatListRefreshed());
                                  },
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          showMessage('Ошибка при открытии чата: $e', context);
                        }
                      }
                    : () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      buildAvatar(fullName: member.fullName, radius: 25, photoPath: member.photoPath),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.fullName!,
                              style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                            Text(member.role.toString(), style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/helpers.dart';
import 'package:waypay/features/chat/presentation/bloc/chat_info/chat_member_cubit.dart';

class EmployesTabContent extends StatelessWidget {
  final int chatId;

  const EmployesTabContent({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatMembersCubit(chatId: chatId)..loadMembers(),
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

              return Padding(
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
              );
            },
          );
        },
      ),
    );
  }
}

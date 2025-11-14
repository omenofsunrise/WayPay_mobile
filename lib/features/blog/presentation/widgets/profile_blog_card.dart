import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_mobile/features/blog/data/models/profile_blog_model.dart';
import 'package:waypay_mobile/features/blog/presentation/cubit/profile_blog_cubit.dart';
import 'package:waypay_mobile/features/chat/data/data_source/chat/chat_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/data_source/message/message_remote_data_source.dart';
import 'package:waypay_mobile/features/chat/data/service/chat_hub_service.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat/chat_bloc.dart';
import 'package:waypay_mobile/features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import 'package:waypay_mobile/features/chat/presentation/screens/chat_screen.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ProfileBlogCard extends StatefulWidget {
  final ProfileBlogModel user;
  final int userId;
  const ProfileBlogCard({super.key, required this.user, required this.userId});

  @override
  State<ProfileBlogCard> createState() => _ProfileBlogCardState();
}

class _ProfileBlogCardState extends State<ProfileBlogCard> {
  bool _isEditing = false;
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.user.description);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveDescription() {
    final newDescription = _controller.text.trim();
    if (newDescription.isNotEmpty) {
      context.read<ProfileBlogCubit>().updateProfile(
        description: newDescription,
        id: widget.user.id,
      );
    }

    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(AppColors.greyLight), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(AppColors.comfPayment),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(AppColors.background),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 45, right: 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildAvatar(
                      photoPath: widget.user.photoPath,
                      fullName: widget.user.fullName,
                      radius: 45,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.fullName,
                            style: AppStyle.manrope(
                              size: 21,
                              weight: FontWeight.w500,
                            ),
                          ),
                          if (widget.user.id == widget.userId)
                            GestureDetector(
                              onTap: _toggleEdit,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Color(AppColors.darkGrey),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isEditing ? 'Отменить' : 'Изменить статус',
                                    style: AppStyle.manrope(
                                      size: 12,
                                      weight: FontWeight.w400,
                                      color: Color(AppColors.darkGrey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            SizedBox.shrink()
                          else
                            Text(
                              widget.user.description ?? 'Нет описания',
                              style: AppStyle.manrope(
                                size: 13,
                                weight: FontWeight.w400,
                                color: widget.user.description == null
                                    ? Color(AppColors.darkGrey)
                                    : Color(AppColors.black),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: LabeledTextField(
                              label: '',
                              controller: _controller,
                              hintText: 'Введите описание',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _saveDescription,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        widget.user.postsCount.toString(),
                        style: AppStyle.manrope(
                          size: 16,
                          weight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Постов',
                        style: AppStyle.manrope(
                          size: 12,
                          weight: FontWeight.w400,
                          color: Color(AppColors.darkGrey),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        widget.user.commentsCount.toString(),
                        style: AppStyle.manrope(
                          size: 16,
                          weight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Коментариев',
                        style: AppStyle.manrope(
                          size: 12,
                          weight: FontWeight.w400,
                          color: Color(AppColors.darkGrey),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        widget.user.likesCount.toString(),
                        style: AppStyle.manrope(
                          size: 16,
                          weight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Реакций',
                        style: AppStyle.manrope(
                          size: 12,
                          weight: FontWeight.w400,
                          color: Color(AppColors.darkGrey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.user.id != widget.userId)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 15,
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final chatApi = getIt<ChatRemoteDataSource>();

                      try {
                        final chat = await chatApi.getOrCreatePrivate(
                          widget.user.id,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка при открытии чата: $e'),
                          ),
                        );
                      }
                    },
                    child: SizedBox(
                      height: 30,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(AppColors.comfPayment),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Отправить сообщение',
                            style: AppStyle.manrope(
                              size: 14,
                              weight: FontWeight.w400,
                              color: Color(AppColors.background),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.user.id == widget.userId) const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

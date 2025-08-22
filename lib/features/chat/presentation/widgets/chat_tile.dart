import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/helpers.dart';

class ChatTile extends StatelessWidget {
  final String chatName;
  final String? avatarPath;
  final String? lastMessage;
  final String? name;
  final String? time;
  final bool isUnreaded;

  const ChatTile({
    super.key,
    required this.chatName,
    this.avatarPath,
    this.lastMessage,
    this.name,
    this.time,
    required this.isUnreaded,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = () {
      final sender = (name ?? '').trim();
      final text = (lastMessage ?? '').trim();
      if (sender.isEmpty && text.isEmpty) return 'Нет сообщений';
      if (sender.isEmpty) return text;
      if (text.isEmpty) return sender;
      return '$sender: $text';
    }();

    return Row(
      children: [
        buildAvatar(fullName: chatName, radius: 28, photoPath: avatarPath),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chatName,
                      style: AppStyle.manrope(size: 14, weight: FontWeight.w600, color: const Color(AppColors.black)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isUnreaded)
                    Row(
                      children: [
                        const SizedBox(
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Color(AppColors.comfPayment), shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  if (time != null)
                    Text(
                      time!,
                      style: AppStyle.manrope(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.darkGrey),
                      ),
                    ),
                ],
              ),
              Text(
                subtitle,
                style: AppStyle.manrope(size: 14, weight: FontWeight.w400, color: const Color(AppColors.darkGrey)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/widgets/helpers.dart';
import 'package:waypay_styles/waypay_styles.dart';

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

    return SizedBox(
      child: Row(
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
                        style: AppStyle.manrope(
                          size: 14,
                          weight: FontWeight.w600,
                          color: const Color(AppColors.black),
                        ),
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
                              decoration: BoxDecoration(
                                color: Color(AppColors.primary),
                                shape: BoxShape.circle,
                              ),
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
                          color: const Color(AppColors.uiBorder),
                        ),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.uiBorder),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

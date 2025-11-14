import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';

class CommentTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final bool isEditing;
  final int? replyToCommentId;
  final Widget avatar;
  final bool enabled;

  const CommentTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    required this.avatar,
    this.isEditing = false,
    this.replyToCommentId,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hintText = isEditing
        ? 'Редактировать комментарий...'
        : (replyToCommentId == null
              ? 'Написать комментарий...'
              : 'Написать ответ...');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: hintText,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(AppColors.primary)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Color(AppColors.primary),
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,

                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image, size: 22),
                      color: Colors.grey[600],
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: onPickImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, size: 22),
                      color: Colors.grey[600],
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: onPickFile,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: onSend,
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.send, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

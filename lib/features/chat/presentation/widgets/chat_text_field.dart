import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';

class ChatTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onPickImage;
  final VoidCallback? onPickFile;
  final bool enabled;

  const ChatTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onPickImage,
    this.onPickFile,
    this.enabled = true,
  });

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  @override
  Widget build(BuildContext context) {
    final hintText = 'Сообщение';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              minLines: 1,
              maxLines: 5,
              cursorColor: Color(AppColors.black),
              onChanged: (value) => setState(() {}),
              style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: hintText,
                fillColor: Colors.white,
                filled: true,
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
                      onPressed: widget.onPickImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, size: 22),
                      color: Colors.grey[600],
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onPickFile,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: widget.onSend,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              child: Icon(
                Icons.send,
                color: widget.controller.text.isEmpty
                    ? Colors.grey
                    : Color(AppColors.comfPayment),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

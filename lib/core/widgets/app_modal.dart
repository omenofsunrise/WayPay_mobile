import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

class AppModal extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final List<PopupMenuEntry>? menuItems;
  final Color backgroundColor;
  final EdgeInsetsGeometry contentPadding;
  final bool showCloseIcon;

  const AppModal({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.menuItems,
    this.backgroundColor = Colors.white,
    this.contentPadding = const EdgeInsets.all(20),
    this.showCloseIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: contentPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (menuItems != null && menuItems!.isNotEmpty)
                    const SizedBox(width: 40)
                  else
                    const SizedBox(width: 0),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppStyle.medium20.copyWith(
                        color: Color(AppColors.primary),
                      ),
                    ),
                  ),
                  if (menuItems != null && menuItems!.isNotEmpty)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (_) => menuItems!,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: content)),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

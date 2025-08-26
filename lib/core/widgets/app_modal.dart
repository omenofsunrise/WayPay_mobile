import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

class AppModal extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final List<PopupMenuEntry>? menuItems;
  final Widget? menu;
  final Color backgroundColor;
  final EdgeInsetsGeometry contentPadding;
  final bool showCloseIcon;

  const AppModal({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.menuItems,
    this.menu,
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: AppStyle.medium20.copyWith(color: Color(AppColors.black)),
                    ),
                  ),
                  if (menu != null)
                    menu!
                  else if (menuItems != null && menuItems!.isNotEmpty)
                    PopupMenuButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz, size: 22),
                      itemBuilder: (_) => menuItems!,
                    ),
                  if (showCloseIcon)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Flexible(child: SingleChildScrollView(child: content)),

              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: actions!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

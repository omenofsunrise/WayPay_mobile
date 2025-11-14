import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';

class DefaultButton extends StatefulWidget {
  final String text;

  final Color? color;
  final Color? textColor;
  final VoidCallback onPressed;
  final bool showIcon;
  final IconData? icon;
  final Widget? iconWidget;

  final bool isGreen;

  const DefaultButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.showIcon = false,
    this.icon,
    this.iconWidget,
    this.isGreen = false,
  });

  @override
  State<DefaultButton> createState() => _DefaultButtonState();
}

class _DefaultButtonState extends State<DefaultButton> {
  @override
  Widget build(BuildContext context) {
    final Color bg =
        widget.color ??
        (widget.isGreen
            ? const Color(AppColors.primary)
            : const Color(AppColors.greyLight));

    final bool isGrey = bg == const Color(AppColors.greyLight);
    final Color fg =
        widget.textColor ??
        (isGrey ? Colors.black : const Color(AppColors.background));

    final Widget? iconWidget =
        widget.iconWidget ??
        (widget.icon != null
            ? Icon(widget.icon, color: fg, size: 20)
            : Icon(Icons.info, color: fg, size: 20));

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showIcon) ...[iconWidget!, const SizedBox(width: 8)],
              Text(widget.text, style: AppStyle.manrope16.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

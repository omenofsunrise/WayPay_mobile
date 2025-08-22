import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

class DefaultButton extends StatefulWidget {
  final String text;

  final Color? color;
  final VoidCallback onPressed;
  final bool showIcon;
  final IconData? icon;

  final bool isGreen;

  const DefaultButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.showIcon = false,
    this.icon,
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
    final Color fg = isGrey ? Colors.black : const Color(AppColors.background);

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.text, style: AppStyle.manrope16.copyWith(color: fg)),
              if (widget.showIcon) ...[
                const SizedBox(width: 8),
                Icon(widget.icon ?? Icons.info, color: fg, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

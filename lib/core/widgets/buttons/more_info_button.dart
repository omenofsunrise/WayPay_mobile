import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/section_title.dart';

class MoreDetailsButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final bool showArrow;

  const MoreDetailsButton({
    Key? key,
    this.text = 'Подробнее',
    required this.onPressed,
    this.color = const Color(0xFF007D88),
    this.padding = const EdgeInsets.all(8.0),
    this.textStyle,
    this.showArrow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: padding,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: color,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionTitle(text: text, color: const Color(AppColors.primary)),
              if (showArrow) ...[
                SizedBox(width: 4),
                Icon(Icons.chevron_right, color: color, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

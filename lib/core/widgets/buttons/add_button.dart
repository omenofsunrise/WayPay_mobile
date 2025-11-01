import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';

class AddButton extends StatefulWidget {
  final Color? color;
  final VoidCallback onPressed;

  const AddButton({super.key, required this.onPressed, this.color});

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton> {
  @override
  Widget build(BuildContext context) {
    final Color bg = const Color(AppColors.primary);

    final bool isGrey = bg == const Color(AppColors.greyLight);
    final Color fg = isGrey ? Colors.black : const Color(AppColors.background);

    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.add, color: fg, size: 24),
      ),
    );
  }
}

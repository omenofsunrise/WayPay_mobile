import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

class DefaultButton extends StatefulWidget {
  final String text;
  final Color? color;
  final VoidCallback onPressed;

  const DefaultButton({
    super.key,
    required this.text,
    this.color,
    required this.onPressed,
  });

  @override
  State<DefaultButton> createState() => _DefaultButtonState();
}

class _DefaultButtonState extends State<DefaultButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: Text(
              widget.text,
              style: AppStyle.manrope16.copyWith(
                color: Color(AppColors.background),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

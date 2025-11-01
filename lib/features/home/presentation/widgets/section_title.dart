import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final double fontSize;
  final double letterSpacing;
  final int? maxLines;
  final TextOverflow overflow;

  const SectionTitle({
    Key? key,
    required this.text,
    this.color = const Color(AppColors.black),
    this.textAlign = TextAlign.left,
    this.fontWeight = FontWeight.w400,
    this.fontSize = 18,
    this.letterSpacing = 0.15,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

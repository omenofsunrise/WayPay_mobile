import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/theme/app_colors.dart';

class LabeledContainer extends StatelessWidget {
  final String label;
  final String text;
  final EdgeInsetsGeometry? margin;

  const LabeledContainer({super.key, required this.label, required this.text, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Color(AppColors.primary)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(text, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

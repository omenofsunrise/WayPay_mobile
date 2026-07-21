import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class AppRadioButton extends StatelessWidget {
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  const AppRadioButton({
    super.key,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: isSelected ? Color(AppColors.primary) : Colors.transparent,
              border: Border.all(color: Color(AppColors.borderColor), width: 1),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppStyle.manrope(size: 18, weight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

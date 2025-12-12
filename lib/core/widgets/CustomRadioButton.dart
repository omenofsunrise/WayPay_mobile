import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';

class CustomRadioButton extends StatelessWidget {
  final bool value;
  final bool groupValue;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String? description;

  const CustomRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RadioGlyph(isSelected: groupValue == value),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppStyle.manrope(
                size: 16,
                weight: FontWeight.w500,
                color: groupValue == value
                    ? const Color(AppColors.black)
                    : Color(AppColors.darkGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioGlyph extends StatelessWidget {
  final bool isSelected;

  const _RadioGlyph({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? Color(AppColors.primary) : Color(AppColors.grey);
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
        color: Colors.transparent,
      ),
      child: isSelected
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: borderColor,
                border: Border.all(color: Colors.transparent, width: 1),
              ),
            )
          : Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
            ),
    );
  }
}

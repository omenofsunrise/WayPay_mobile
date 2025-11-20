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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: groupValue == value
                ? Color(AppColors.primary)
                : Color(AppColors.grey),
          ),
          color: groupValue == value
              ? Color(AppColors.primary).withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: groupValue == value
                      ? Color(AppColors.primary)
                      : Color(AppColors.grey),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: groupValue == value
                      ? Color(AppColors.primary)
                      : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w500,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: AppStyle.manrope(
                        size: 12,
                        weight: FontWeight.w400,
                        color: Color(AppColors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
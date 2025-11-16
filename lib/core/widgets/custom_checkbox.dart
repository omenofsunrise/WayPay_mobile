import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final MainAxisAlignment alignment;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          // Кастомный чекбокс
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? Color(AppColors.primary) : Colors.transparent,
              border: Border.all(
                color: value ? Color(AppColors.primary) : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: value
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          // Лейбл
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

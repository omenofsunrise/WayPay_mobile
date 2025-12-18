import 'package:flutter/material.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';
import 'package:waypay_styles/waypay_styles.dart';

class PriorityDropdown extends StatelessWidget {
  final TaskPriority selectedPriority;
  final void Function(TaskPriority) onChanged;
  final bool showAllOption;

  const PriorityDropdown({
    super.key,
    required this.selectedPriority,
    required this.onChanged,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final options = showAllOption
        ? TaskPriority.values
        : TaskPriority.values.where((e) => e != TaskPriority.all).toList();

    final effectiveSelectedPriority = options.contains(selectedPriority)
        ? selectedPriority
        : options.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Color(AppColors.primary)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButton<TaskPriority>(
        isExpanded: true,
        underline: const SizedBox(),
        value: effectiveSelectedPriority,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        items: options.map((option) {
          return DropdownMenuItem<TaskPriority>(
            value: option,
            child: Row(
              children: [
                Text(
                  option.label,
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        icon: const Icon(Icons.arrow_drop_down),
        dropdownColor: Colors.white,
      ),
    );
  }
}

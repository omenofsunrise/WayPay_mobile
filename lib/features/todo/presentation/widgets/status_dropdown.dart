import 'package:flutter/material.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';
import 'package:waypay_styles/waypay_styles.dart';

class StatusDropdown extends StatelessWidget {
  final TaskStatus? selectedStatus;
  final void Function(TaskStatus?) onChanged;

  const StatusDropdown({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = <TaskStatus?>[
      null,
      TaskStatus.pending,
      TaskStatus.inProgress,
      TaskStatus.review,
      TaskStatus.done,
    ];

    final effectiveSelectedStatus = options.contains(selectedStatus)
        ? selectedStatus
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Color(AppColors.primary)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButton<TaskStatus?>(
        isExpanded: true,
        underline: const SizedBox(),
        value: effectiveSelectedStatus,
        onChanged: (value) => onChanged(value),
        items: options.map((option) {
          final label = option == null
              ? 'Все'
              : {
                  TaskStatus.pending: 'К выполнению',
                  TaskStatus.inProgress: 'В работе',
                  TaskStatus.review: 'На проверке',
                  TaskStatus.done: 'Выполнено',
                }[option]!;

          return DropdownMenuItem<TaskStatus?>(
            value: option,
            child: Text(
              label,
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
        icon: const Icon(Icons.arrow_drop_down),
        dropdownColor: Colors.white,
      ),
    );
  }
}

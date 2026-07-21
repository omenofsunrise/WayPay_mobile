import 'package:flutter/material.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class TaskStatusDropdown extends StatelessWidget {
  final TodoTask task;
  final Future<void> Function(TaskStatus status) onStatusChange;

  const TaskStatusDropdown({
    super.key,
    required this.task,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    const order = <TaskStatus>[
      TaskStatus.pending,
      TaskStatus.inProgress,
      TaskStatus.review,
      TaskStatus.done,
    ];

    return PopupMenuButton<TaskStatus>(
      padding: EdgeInsets.zero,
      color: Color(AppColors.background),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Color(AppColors.greyLight), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.sync_alt, size: 22, color: Color(AppColors.uiBorder)),
      onSelected: (status) {
        if (status != task.taskStatus) {
          onStatusChange(status);
        }
      },
      itemBuilder: (context) {
        return order.map((status) {
          final isCurrent = status == task.taskStatus;
          return PopupMenuItem<TaskStatus>(
            value: status,
            enabled: !isCurrent,
            height: 32,
            child: Center(
              child: Text(
                status.label,
                style: AppStyle.manrope(
                  size: 14,
                  weight: FontWeight.w400,
                  color: isCurrent ? Color(AppColors.primary) : Colors.black,
                ),
              ),
            ),
          );
        }).toList();
      },
    );
  }
}

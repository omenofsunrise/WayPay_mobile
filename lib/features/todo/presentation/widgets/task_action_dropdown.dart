import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

enum TaskAction { edit, delete }

class TaskActionsDropdown extends StatelessWidget {
  final Future<void> Function(TaskAction action) onActionSelected;

  const TaskActionsDropdown({super.key, required this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskAction>(
      padding: EdgeInsets.zero,
      color: Color(AppColors.background),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.more_horiz, size: 22, color: Color(AppColors.uiBorder)),
      onSelected: (action) {
        onActionSelected(action);
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<TaskAction>(
            value: TaskAction.edit,
            height: 32,
            child: Row(
              children: [
                Icon(Icons.edit, size: 24, color: Color(AppColors.uiBorder)),
                SizedBox(width: 10),
                Text(
                  'Изменить',
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<TaskAction>(
            value: TaskAction.delete,
            height: 32,
            child: Row(
              children: [
                Icon(Icons.delete, size: 24, color: Color(AppColors.uiBorder)),
                SizedBox(width: 10),
                Text(
                  'Удалить',
                  style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }
}

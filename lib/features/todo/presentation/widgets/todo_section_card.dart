import 'package:flutter/material.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/todo_task_card.dart';

class TodoSectionItem {
  const TodoSectionItem({
    required this.title,
    required this.status,
    required this.tasks,
  });

  final String title;
  final TaskStatus status;
  final List<TodoTask> tasks;
}

class TodoSectionCard extends StatelessWidget {
  const TodoSectionCard({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.onToggle,
    required this.onCommentsTap,
    required this.noteCounts,
  });

  final TodoSectionItem item;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(TodoTask task) onCommentsTap;
  final Map<int, int> noteCounts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(AppColors.white),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000809),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: Color(0x05000809),
                  offset: Offset(0, 0),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppStyle.manrope(
                            size: 18,
                            weight: FontWeight.w500,
                            color: const Color(AppColors.black),
                          ),
                        ),
                      ),
                      Text(
                        item.tasks.length.toString(),
                        style: AppStyle.manrope(
                          size: 18,
                          weight: FontWeight.w600,
                          color: const Color(AppColors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF111111),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            if (item.tasks.isEmpty)
              const Text(
                'Нет задач',
                style: TextStyle(color: Color(AppColors.uiBorder)),
              )
            else
              Column(
                children: item.tasks
                    .map(
                      (task) => TodoTaskCard(
                        task: task,
                        onCommentsTap: () => onCommentsTap(task),
                        commentsCount: noteCounts[task.id] ?? 0,
                      ),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }
}

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
    required this.onTaskDropped,
    required this.onDragUpdate,
  });

  final TodoSectionItem item;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(TodoTask task) onCommentsTap;
  final Map<int, int> noteCounts;
  final void Function(TodoTask task, TaskStatus newStatus) onTaskDropped;
  final void Function(Offset globalPosition) onDragUpdate;

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
            DragTarget<TodoTask>(
              onWillAcceptWithDetails: (details) =>
                  details.data.taskStatus != item.status,
              onAcceptWithDetails: (details) =>
                  onTaskDropped(details.data, item.status),
              builder: (context, candidateData, rejectedData) {
                final isActive = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0x1A25CBA1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: const Color(0xFF25CBA1),
                            width: 1,
                          )
                        : null,
                  ),
                  child: item.tasks.isEmpty
                      ? const Text(
                          'Нет задач',
                          style: TextStyle(color: Color(AppColors.uiBorder)),
                        )
                      : Column(
                          children: item.tasks
                              .map(
                                (task) => LongPressDraggable<TodoTask>(
                                  data: task,
                                  dragAnchorStrategy:
                                      pointerDragAnchorStrategy,
                                  onDragUpdate: (details) =>
                                      onDragUpdate(details.globalPosition),
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width -
                                                32,
                                      ),
                                      child: Opacity(
                                        opacity: 0.9,
                                        child: TodoTaskCard(
                                          task: task,
                                          onCommentsTap: () {},
                                          commentsCount:
                                              noteCounts[task.id] ?? 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.4,
                                    child: TodoTaskCard(
                                      task: task,
                                      onCommentsTap: () => onCommentsTap(task),
                                      commentsCount: noteCounts[task.id] ?? 0,
                                    ),
                                  ),
                                  child: TodoTaskCard(
                                    task: task,
                                    onCommentsTap: () => onCommentsTap(task),
                                    commentsCount: noteCounts[task.id] ?? 0,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';

class TodoTaskCard extends StatelessWidget {
  const TodoTaskCard({
    super.key,
    required this.task,
    required this.onCommentsTap,
    required this.commentsCount,
  });

  final TodoTask task;
  final VoidCallback onCommentsTap;
  final int commentsCount;

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) return '—';
    return DateFormat('dd MMMM', 'ru_RU').format(deadline);
  }

  bool get _isOverdue {
    final deadline = task.deadline;
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline.isBefore(DateTime(now.year, now.month, now.day)) &&
        task.taskStatus != TaskStatus.done;
  }

  String get _assigneeName {
    if ((task.employeeName ?? '').isNotEmpty) return task.employeeName!;
    if ((task.responsibleName ?? '').isNotEmpty) return task.responsibleName!;
    return 'Не назначено';
  }

  String get _initials {
    final parts = _assigneeName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.bookmark,
                    color: Color(0xFFFF5A5A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppStyle.manrope(
                        size: 16,
                        weight: FontWeight.w500,
                        color: const Color(AppColors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFF6B717C),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDeadline(task.deadline),
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w400,
                      color: const Color(AppColors.uiBorder),
                    ),
                  ),
                  const Spacer(),
                  if (_isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5A5A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Просрочена',
                        style: AppStyle.manrope(
                          size: 12,
                          weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5A5A),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials,
                      style: AppStyle.manrope(
                        size: 12,
                        weight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _assigneeName,
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w500,
                        color: const Color(AppColors.black),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onCommentsTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 22,
                            color: Color(0xFF6B717C),
                          ),
                          if (commentsCount > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25CBA1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  commentsCount.toString(),
                                  style: AppStyle.manrope(
                                    size: 10,
                                    weight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

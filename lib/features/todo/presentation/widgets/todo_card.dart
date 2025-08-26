import 'package:flutter/material.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_modal.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay/core/widgets/helpers.dart';
import 'package:waypay/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:waypay/features/profile/data/models/employee.dart';
import 'package:waypay/features/todo/data/data_soucres/task_remote_data_source.dart';
import 'package:waypay/features/todo/data/models/task_request.dart';
import 'package:waypay/features/todo/data/models/todo_model.dart';
import 'package:waypay/features/todo/presentation/widgets/employee_dropdown.dart';
import 'package:waypay/features/todo/presentation/widgets/priority_dropdown.dart';
import 'package:waypay/features/todo/presentation/widgets/task_action_dropdown.dart';
import 'package:waypay/features/todo/presentation/widgets/task_status_dropdown.dart';

class TodoCard extends StatefulWidget {
  final TodoTask task;
  final VoidCallback? onChanged;

  /// 🔹 новый колбэк — для мгновенного обновления UI
  final ValueChanged<TaskStatus>? onLocalStatusChange;

  const TodoCard({super.key, required this.task, this.onChanged, this.onLocalStatusChange});

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  final TaskRemoteDataSource _taskDataSource = getIt<TaskRemoteDataSource>();

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.task.deadline != null && widget.task.deadline!.isBefore(DateTime.now());

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(AppColors.background),
          border: isOverdue ? Border(left: BorderSide(color: Color(AppColors.red), width: 4)) : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 7, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bookmark, size: 22, color: getPriorityColor(widget.task.priority)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      child: Text(
                        widget.task.title,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: AppStyle.manrope(size: 14, weight: FontWeight.w500, color: Color(AppColors.black)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 🔹 дропдаун статуса — теперь с оптимистичным апдейтом
                  TaskStatusDropdown(
                    task: widget.task,
                    onStatusChange: (TaskStatus status) async {
                      final old = widget.task.taskStatus;
                      // мгновенно обновляем UI сверху через родителя
                      widget.onLocalStatusChange?.call(status);

                      try {
                        switch (status) {
                          case TaskStatus.pending:
                            await _taskDataSource.patchPendingTasks(widget.task.id);
                            break;
                          case TaskStatus.inProgress:
                            await _taskDataSource.patchInProgressTasks(widget.task.id);
                            break;
                          case TaskStatus.review:
                            await _taskDataSource.patchReviewTasks(widget.task.id);
                            break;
                          case TaskStatus.done:
                            await _taskDataSource.patchDoneTasks(widget.task.id);
                            break;
                        }
                        if (context.mounted && widget.onChanged != null) {
                          widget.onChanged!(); // фоновая синхронизация с бэком
                        }
                      } catch (e) {
                        // откат при ошибке
                        widget.onLocalStatusChange?.call(old);
                        if (!context.mounted) return;
                        showMessage('Ошибка смены статуса: $e', context);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  TaskActionsDropdown(
                    onActionSelected: (action) async {
                      switch (action) {
                        case TaskAction.edit:
                          showEditTodoModal(context, widget.task);
                          break;
                        case TaskAction.delete:
                          _deleteTask();
                          break;
                      }
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.calendar_month, size: 22, color: Color(AppColors.grey)),
                  const SizedBox(width: 2),
                  Text(
                    formatDate(widget.task.deadline),
                    style: AppStyle.manrope(size: 12, weight: FontWeight.w400, color: Color(AppColors.black)),
                  ),
                  const SizedBox(width: 10),
                  if (isOverdue)
                    SizedBox(
                      height: 20,
                      width: 100,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(AppColors.red), borderRadius: BorderRadius.circular(16)),
                        child: Center(
                          child: Text(
                            'Просрочено',
                            style: AppStyle.manrope(
                              size: 12,
                              weight: FontWeight.w400,
                              color: Color(AppColors.background),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  buildAvatar(photoPath: widget.task.employeePhotoPath, fullName: widget.task.employeeName, radius: 15),
                  SizedBox(width: 4),
                  Text(
                    widget.task.employeeName ?? 'Нет исполнителя',
                    style: AppStyle.manrope(size: 12, weight: FontWeight.w400, color: Color(AppColors.black)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(AppColors.red);
      case TaskPriority.medium:
        return const Color(AppColors.yellow);
      case TaskPriority.low:
        return const Color(AppColors.primaryLight);
      default:
        return const Color(AppColors.primaryLight);
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Дата не найдена';
    }
    final day = date.day;
    final monthName = _monthName(date.month);
    return '$day $monthName';
    // Если нужен год: return '$day $monthName ${date.year}';
  }

  String _monthName(int month) {
    const monthNames = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return monthNames[month - 1];
  }

  Future<void> _deleteTask() async {
    final confirmed = await showConfirmDialog(context: context);
    if (confirmed) {
      try {
        await _taskDataSource.deleteTask(widget.task.id);
        if (mounted && widget.onChanged != null) {
          widget.onChanged!();
        }
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        showMessage('Ошибка при удалении: $e', context);
      }
    }
  }

  Future<void> _editTask(TaskRequest task) async {
    try {
      await _taskDataSource.updateTask(widget.task.id, task);
      if (mounted && widget.onChanged != null) {
        widget.onChanged!();
      }
    } catch (e) {
      showMessage('Ошибка при редактирование: $e', context);
    }
  }

  void showEditTodoModal(BuildContext externalContext, TodoTask task) async {
    final titleController = TextEditingController(text: task.title);
    final deadlineController = TextEditingController(
      text: task.deadline != null
          ? '${task.deadline!.day.toString().padLeft(2, '0')}.${task.deadline!.month.toString().padLeft(2, '0')}.${task.deadline!.year}'
          : '',
    );

    final EmployeeRemoteDataSource empDataSource = getIt<EmployeeRemoteDataSource>();

    String? titleError;
    String? deadlineError;

    TaskPriority selectedPriority = task.priority;

    EmployeeName? selectedExecutor;
    EmployeeName? selectedResponsible;

    if (task.employeeId != null) {
      final empJson1 = await empDataSource.getEmployeeById(task.employeeId!);
      selectedExecutor = EmployeeName(id: empJson1['id'] as int, fullName: empJson1['fullName'] as String);
    }

    if (task.responsibleId != null) {
      final empJson2 = await empDataSource.getEmployeeById(task.responsibleId!);
      selectedResponsible = EmployeeName(id: empJson2['id'] as int, fullName: empJson2['fullName'] as String);
    }

    DateTime? parsedDeadline;
    final deadlineRegExp = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');

    bool validateInputs() {
      bool isValid = true;
      titleError = null;
      deadlineError = null;

      if (titleController.text.trim().isEmpty) {
        titleError = 'Введите заголовок';
        isValid = false;
      }

      final dateText = deadlineController.text.trim();
      if (!deadlineRegExp.hasMatch(dateText)) {
        deadlineError = 'Введите дату в формате дд.мм.гггг';
        isValid = false;
      } else {
        final match = deadlineRegExp.firstMatch(dateText)!;
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        try {
          final date = DateTime(year, month, day);
          final today = DateTime.now();
          if (date.isBefore(DateTime(today.year, today.month, today.day))) {
            deadlineError = 'Дата не может быть в прошлом';
            isValid = false;
          } else {
            parsedDeadline = date;
          }
        } catch (_) {
          deadlineError = 'Некорректная дата';
          isValid = false;
        }
      }

      return isValid;
    }

    if (!externalContext.mounted) return;

    showDialog(
      context: externalContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AppModal(
              backgroundColor: Color(AppColors.background),
              title: 'Создать задачу',
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledTextField(
                      label: 'Заголовок',
                      controller: titleController,
                      errorText: titleError,
                      onChanged: (_) => setState(validateInputs),
                    ),
                    LabeledTextField(
                      label: 'Дата завершения (дд.мм.гггг)',
                      controller: deadlineController,
                      keyboardType: TextInputType.datetime,
                      format: LabeledTextFieldFormat.birthdate,
                      errorText: deadlineError,
                      onChanged: (_) => setState(validateInputs),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Приоритет',
                      style: AppStyle.medium16.copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    PriorityDropdown(
                      selectedPriority: selectedPriority,
                      showAllOption: false,
                      onChanged: (value) {
                        setState(() {
                          selectedPriority = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Исполнитель',
                      style: AppStyle.medium16.copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    EmployeeDropdown(
                      selectedEmployee: selectedExecutor,
                      onChanged: (value) {
                        setState(() {
                          selectedExecutor = value;
                        });
                      },
                      isExecutorDropdown: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ответственный',
                      style: AppStyle.medium16.copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    EmployeeDropdown(
                      selectedEmployee: selectedResponsible,
                      onChanged: (value) {
                        setState(() {
                          selectedResponsible = value;
                        });
                      },
                      showNoResponsibleOption: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DefaultButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            text: 'Отмена',
                            isGreen: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DefaultButton(
                            onPressed: () {
                              if (!validateInputs()) {
                                setState(() {});
                                return;
                              }
                              TaskRequest taskRequest = TaskRequest(
                                title: titleController.text,
                                employeeId: selectedExecutor?.id,
                                responsibleId: selectedResponsible?.id,
                                priority: selectedPriority,
                                deadline: parsedDeadline,
                              );
                              _editTask(taskRequest);
                              Navigator.of(dialogContext).pop();
                            },
                            text: 'Изменить',
                            isGreen: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

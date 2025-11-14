import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay_mobile/core/widgets/app_modal.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/todo/data/models/task_request.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';
import 'package:waypay_mobile/features/todo/presentation/bloc/task_bloc.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/app_radio.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/employee_dropdown.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/priority_dropdown.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/status_dropdown.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/todo_card.dart';
import 'package:waypay_mobile/routes/routes.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TaskDragData {
  final TodoTask task;
  _TaskDragData(this.task);
}

class _TodoScreenState extends State<TodoScreen> {
  final _tokenStorage = TokenStorage();

  // 🔹 контроллер и ключ списка — для автоскролла при драге
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();

  bool onlyMyTasks = false;
  bool _isDragging = false;
  late final bool isSuperAdmin;
  TaskPriority? selectedPriority = TaskPriority.all;
  EmployeeName? selectedEmployee;
  TaskStatus? visibleStatus;

  // 🔹 локальные оптимистичные статусы: taskId -> новый статус
  final Map<int, TaskStatus> _optimistic = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  void _loadTasks() {
    final taskBloc = context.read<TaskBloc>();

    taskBloc.add(
      LoadActiveTasks(
        onlyMine: onlyMyTasks,
        priority: selectedPriority == TaskPriority.all
            ? null
            : selectedPriority,
        taskEmployeeId: selectedEmployee?.id,
        status: visibleStatus,
      ),
    );
  }

  void _onFiltersChanged() {
    setState(() {
      _loadTasks();
    });
  }

  // 🔹 Автоскролл во время перетаскивания
  void _maybeAutoScroll(Offset globalPosition) {
    final ctx = _listKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final height = box.size.height;
    final bottom = top + height;

    const edge = 80.0; // чувствительная зона у краёв
    const step = 14.0; // шаг прокрутки

    if (!_scrollController.hasClients) return;

    if (globalPosition.dy < top + edge) {
      final newOffset = (_scrollController.offset - step).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(newOffset);
    } else if (globalPosition.dy > bottom - edge) {
      final newOffset = (_scrollController.offset + step).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(newOffset);
    }
  }

  void _openFilterModal() {
    showDialog(
      context: context,
      builder: (_) => AppModal(
        title: 'Фильтры',
        backgroundColor: const Color(AppColors.background),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PriorityDropdown(
              selectedPriority: selectedPriority ?? TaskPriority.all,
              onChanged: (value) {
                setState(() => selectedPriority = value);
              },
            ),
            const SizedBox(height: 12),
            EmployeeDropdown(
              selectedEmployee: selectedEmployee,
              showAllOption: true,
              onChanged: (value) {
                setState(() => selectedEmployee = value);
              },
            ),
          ],
        ),
        actions: [
          DefaultButton(
            text: 'Сбросить',
            onPressed: () {
              setState(() {
                selectedPriority = TaskPriority.all;
                selectedEmployee = null;
              });
              _loadTasks();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          DefaultButton(
            text: 'Применить',
            isGreen: true,
            onPressed: () {
              _loadTasks();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection(
    String title,
    TaskStatus sectionStatus,
    List<TodoTask> tasks,
  ) {
    bool isHovering = false;

    return StatefulBuilder(
      builder: (context, setLocal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: DragTarget<_TaskDragData>(
            onWillAccept: (data) {
              final ok = data != null && data.task.taskStatus != sectionStatus;
              setLocal(() => isHovering = ok);
              return ok;
            },
            onLeave: (_) => setLocal(() => isHovering = false),
            onAccept: (data) {
              setLocal(() => isHovering = false);
              // 🔹 оптимистично обновляем UI
              setState(() {
                _optimistic[data.task.id] = sectionStatus;
              });
              // и шлём событие в блок
              context.read<TaskBloc>().add(
                UpdateTaskStatus(
                  taskId: data.task.id,
                  newStatus: sectionStatus,
                ),
              );
            },
            builder: (context, candidate, rejected) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(AppColors.lightGreyBackground),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    width: 1.5,
                    color: isHovering
                        ? Color(AppColors.primaryLight)
                        : Color(AppColors.uncomfPayment),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            title,
                            style: AppStyle.manrope(
                              size: 16,
                              weight: FontWeight.w600,
                              color: Color(AppColors.black),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            tasks.length.toString(),
                            style: AppStyle.manrope(
                              size: 16,
                              weight: FontWeight.w600,
                              color: Color(AppColors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          'Задачи отсутствуют',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: tasks.map((task) {
                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: LongPressDraggable<_TaskDragData>(
                                data: _TaskDragData(task),
                                dragAnchorStrategy: pointerDragAnchorStrategy,
                                onDragStarted: () =>
                                    setState(() => _isDragging = true),
                                onDragEnd: (_) =>
                                    setState(() => _isDragging = false),
                                onDraggableCanceled: (_, __) =>
                                    setState(() => _isDragging = false),
                                onDragCompleted: () =>
                                    setState(() => _isDragging = false),
                                // 🔹 критично: обновляем автоскролл при движении
                                onDragUpdate: (details) =>
                                    _maybeAutoScroll(details.globalPosition),
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width -
                                          64,
                                    ),
                                    child: Opacity(
                                      opacity: 0.9,
                                      child: TodoCard(
                                        task: task,
                                        onChanged: _loadTasks,
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.4,
                                  child: TodoCard(
                                    task: task,
                                    onChanged: _loadTasks,
                                  ),
                                ),
                                child: TodoCard(
                                  task: task,
                                  onChanged: _loadTasks,

                                  onLocalStatusChange: (newStatus) {
                                    setState(() {
                                      _optimistic[task.id] = newStatus;
                                    });
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(AppColors.grey)),
        backgroundColor: const Color(AppColors.background),
        title: Text(
          'To do',
          style: AppStyle.medium20.copyWith(
            color: const Color(AppColors.black),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showCreateTodoModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _openFilterModal,
          ),
        ],
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(AppColors.background),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 🔹 слушаем успешные загрузки, чтобы очищать оптимистично изменённые элементы
            BlocListener<TaskBloc, TaskState>(
              listenWhen: (prev, curr) => curr is TaskLoaded,
              listener: (context, state) {
                if (state is TaskLoaded) {
                  setState(() {
                    // чистим те overrides, которые уже совпали с сервером
                    for (final t in state.tasks) {
                      final o = _optimistic[t.id];
                      if (o != null && o == t.taskStatus) {
                        _optimistic.remove(t.id);
                      }
                    }
                  });
                }
              },
              child: Expanded(
                child: BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    if (state is TaskLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is TaskError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  if (state.message.contains('Сессия')) {
                                    _logout();
                                  } else {
                                    _loadTasks();
                                  }
                                },
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is TaskLoaded) {
                      final pending = <TodoTask>[];
                      final inProgress = <TodoTask>[];
                      final review = <TodoTask>[];
                      final done = <TodoTask>[];

                      // 🔹 применяем локальные оптимистичные статусы
                      for (var task in state.tasks) {
                        final effectiveStatus =
                            _optimistic[task.id] ?? task.taskStatus;
                        switch (effectiveStatus) {
                          case TaskStatus.pending:
                            pending.add(
                              task.copyWith(taskStatus: effectiveStatus),
                            );
                            break;
                          case TaskStatus.inProgress:
                            inProgress.add(
                              task.copyWith(taskStatus: effectiveStatus),
                            );
                            break;
                          case TaskStatus.review:
                            review.add(
                              task.copyWith(taskStatus: effectiveStatus),
                            );
                            break;
                          case TaskStatus.done:
                            done.add(
                              task.copyWith(taskStatus: effectiveStatus),
                            );
                            break;
                        }
                      }

                      final sections =
                          <
                            ({
                              String title,
                              TaskStatus status,
                              List<TodoTask> data,
                            })
                          >[
                            (
                              title: 'К выполнению',
                              status: TaskStatus.pending,
                              data: pending,
                            ),
                            (
                              title: 'В работе',
                              status: TaskStatus.inProgress,
                              data: inProgress,
                            ),
                            (
                              title: 'На проверке',
                              status: TaskStatus.review,
                              data: review,
                            ),
                            (
                              title: 'Выполнено',
                              status: TaskStatus.done,
                              data: done,
                            ),
                          ];

                      final visibleSections = visibleStatus == null
                          ? sections
                          : sections
                                .where((s) => s.status == visibleStatus)
                                .toList();

                      return Refresher(
                        onRefresh: () async => _loadTasks(),
                        content: ListView(
                          key: _listKey,
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          children: [
                            for (final s in visibleSections)
                              _buildTaskSection(s.title, s.status, s.data),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showCreateTodoModal(BuildContext externalContext) async {
  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final AuthRemoteDataSource dataSource = getIt<AuthRemoteDataSource>();

  String? titleError;
  String? deadlineError;
  TaskPriority? selectedPriority = TaskPriority.low;

  final info = await dataSource.getAuthInfo();
  final employeeJson = info['employee'] as Map<String, dynamic>?;

  EmployeeName? selectedExecutor;
  if (employeeJson != null) {
    selectedExecutor = EmployeeName(
      id: employeeJson['id'] as int,
      fullName: employeeJson['fullName'] as String,
    );
  }

  EmployeeName? selectedResponsible;
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
                    onChanged: (_) {
                      setState(() {
                        validateInputs();
                      });
                    },
                  ),
                  LabeledTextField(
                    label: 'Дата завершения (дд.мм.гггг)',
                    controller: deadlineController,
                    keyboardType: TextInputType.datetime,
                    format: LabeledTextFieldFormat.birthdate,
                    errorText: deadlineError,
                    onChanged: (_) => setState(() => validateInputs()),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Приоритет',
                    style: AppStyle.medium16.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PriorityDropdown(
                    selectedPriority: selectedPriority!,
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
                    style: AppStyle.medium16.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
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
                    style: AppStyle.medium16.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
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

                            final newTask = TaskRequest(
                              title: titleController.text.trim(),
                              deadline: parsedDeadline,
                              priority: selectedPriority!,
                              employeeId: selectedExecutor?.id,
                              responsibleId: selectedResponsible?.id,
                            );

                            externalContext.read<TaskBloc>().add(
                              CreateTask(newTask),
                            );
                            Navigator.of(dialogContext).pop();
                          },
                          text: 'Создать',
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

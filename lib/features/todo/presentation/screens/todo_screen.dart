import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';
import 'package:waypay_mobile/features/todo/data/models/todo_model.dart';
import 'package:waypay_mobile/features/todo/presentation/bloc/task_bloc.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/task_comments_sheet.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/task_create_sheet.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/todo_add_button.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/todo_error_state.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/todo_section_card.dart';
import 'package:waypay_mobile/features/todo/presentation/widgets/todo_utils.dart';
import 'package:waypay_styles/waypay_styles.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late final TaskBloc _taskBloc;
  final ScrollController _scrollController = ScrollController();
  final Map<int, int> _noteCounts = {};
  final Map<TaskStatus, bool> _expanded = {
    TaskStatus.pending: false,
    TaskStatus.inProgress: false,
    TaskStatus.review: false,
    TaskStatus.done: false,
  };

  @override
  void initState() {
    super.initState();
    _taskBloc = TaskBloc()..add(LoadActiveTasks());
  }

  @override
  void dispose() {
    _taskBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSection(TaskStatus status) {
    setState(() {
      _expanded[status] = !(_expanded[status] ?? false);
    });
  }

  Future<void> _openComments(TodoTask task) async {
    BottomNavController.instance.hide();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.black.withOpacity(0.4),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TaskCommentsSheet(
        task: task,
        onCountChanged: (count) {
          setState(() => _noteCounts[task.id] = count);
        },
      ),
    );
    BottomNavController.instance.show();
  }

  Future<void> _openCreateTask() async {
    BottomNavController.instance.hide();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.black.withOpacity(0.4),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TaskCreateSheet(
        onSubmit: (request) => _taskBloc.add(CreateTask(request)),
      ),
    );
    BottomNavController.instance.show();
  }

  void _autoScrollOnDrag(Offset globalPosition) {
    if (!_scrollController.hasClients) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final local = renderBox.globalToLocal(globalPosition);
    const edge = 80.0;
    const step = 14.0;
    final height = renderBox.size.height;
    final position = _scrollController.position;
    double target = position.pixels;

    if (local.dy < edge) {
      target = (position.pixels - step).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
    } else if (local.dy > height - edge) {
      target = (position.pixels + step).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
    } else {
      return;
    }

    if (target != position.pixels) {
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: BlocProvider.value(
          value: _taskBloc,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Header(
                    title: 'Todo',
                    showBackButton: false,
                    showNotifications: false,
                    showAvatar: false,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [AddTodoButton(onTap: _openCreateTask)],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, state) {
                    if (state is TaskLoading || state is TaskInitial) {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (state is TaskError) {
                      return SliverToBoxAdapter(
                        child: TodoErrorState(
                          message: state.message,
                          onRetry: () => _taskBloc.add(LoadActiveTasks()),
                        ),
                      );
                    }
                    if (state is TaskLoaded) {
                      final grouped = groupTasksByStatus(state.tasks);
                      final sections = TaskStatus.values.map((status) {
                        return TodoSectionItem(
                          title: status.label,
                          status: status,
                          tasks: grouped[status] ?? const [],
                        );
                      }).toList();

                      if (sections.every((s) => s.tasks.isEmpty)) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'Нет задач',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(AppColors.uiBorder),
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = sections[index];
                          return TodoSectionCard(
                            item: item,
                            isExpanded: _expanded[item.status] ?? false,
                            onToggle: () => _toggleSection(item.status),
                            onCommentsTap: _openComments,
                            noteCounts: _noteCounts,
                            onTaskDropped: (task, newStatus) {
                              if (task.taskStatus == newStatus) return;
                              _taskBloc.add(
                                UpdateTaskStatus(
                                  taskId: task.id,
                                  newStatus: newStatus,
                                ),
                              );
                            },
                            onDragUpdate: _autoScrollOnDrag,
                          );
                        }, childCount: sections.length),
                      );
                    }

                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

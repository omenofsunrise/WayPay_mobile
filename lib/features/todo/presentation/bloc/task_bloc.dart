import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/todo/data/data_soucres/task_remote_data_source.dart';
import 'package:waypay/features/todo/data/models/get_active_task_query.dart';
import 'package:waypay/features/todo/data/models/task_request.dart';
import 'package:waypay/features/todo/data/models/todo_model.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRemoteDataSource _taskDataSource = getIt<TaskRemoteDataSource>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  TaskBloc() : super(TaskInitial()) {
    on<LoadActiveTasks>(_onLoadActiveTasks);
    on<CreateTask>(_onCreateTask);
    on<UpdateTaskStatus>(_onUpdateTaskStatus);
  }

  Future<void> _onLoadActiveTasks(
    LoadActiveTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(TaskError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final query = GetActiveTasksQuery(
        onlyMine: event.onlyMine ?? false,
        includeCompleted: true,
        priority: event.priority,
        taskEmployeeId: event.taskEmployeeId,
      );

      final tasks = await _taskDataSource.fetchActiveTasks(query);

      emit(
        TaskLoaded(
          tasks: tasks,
          hasMoreData: false,
          currentPage: 1,
          totalPages: 1,
        ),
      );
    } catch (e) {
      emit(TaskError('Ошибка при загрузке активных задач: $e'));
    }
  }

  Future<void> _onCreateTask(CreateTask event, Emitter<TaskState> emit) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(TaskError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      await _taskDataSource.createTask(event.task);

      add(LoadActiveTasks());
    } catch (e) {
      final currentState = state;
      if (currentState is TaskLoaded) {
        emit(
          currentState.copyWith(errorMessage: 'Ошибка при создании задачи: $e'),
        );
      } else {
        emit(TaskError('Ошибка при создании задачи: $e'));
      }
    }
  }

  Future<void> _onUpdateTaskStatus(
    UpdateTaskStatus event,
    Emitter<TaskState> emit,
  ) async {
    final currentState = state;

    if (currentState is TaskLoaded) {
      final originalTasks = List<TodoTask>.from(currentState.tasks);

      final updatedTasks = currentState.tasks.map((t) {
        if (t.id == event.taskId) {
          return t.copyWith(taskStatus: event.newStatus);
        }
        return t;
      }).toList();

      emit(currentState.copyWith(tasks: updatedTasks));

      try {
        switch (event.newStatus) {
          case TaskStatus.pending:
            await _taskDataSource.patchPendingTasks(event.taskId);
            break;
          case TaskStatus.inProgress:
            await _taskDataSource.patchInProgressTasks(event.taskId);
            break;
          case TaskStatus.review:
            await _taskDataSource.patchReviewTasks(event.taskId);
            break;
          case TaskStatus.done:
            await _taskDataSource.patchDoneTasks(event.taskId);
            break;
        }
      } catch (e) {
        emit(currentState.copyWith(tasks: originalTasks));
        emit(TaskError('Не удалось обновить статус задачи: $e'));
      }
    }
  }
}

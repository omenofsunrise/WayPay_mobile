part of 'task_bloc.dart';

abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TodoTask> tasks;
  final bool hasMoreData;
  final int currentPage;
  final int totalPages;
  final String? errorMessage;

  TaskLoaded({
    required this.tasks,
    required this.hasMoreData,
    required this.currentPage,
    required this.totalPages,
    this.errorMessage,
  });

  TaskLoaded copyWith({
    List<TodoTask>? tasks,
    bool? hasMoreData,
    int? currentPage,
    int? totalPages,
    String? errorMessage,
  }) {
    return TaskLoaded(
      tasks: tasks ?? this.tasks,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TaskCreateSuccess extends TaskState {}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}

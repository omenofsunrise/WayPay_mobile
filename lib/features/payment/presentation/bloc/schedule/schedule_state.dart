part of 'schedule_bloc.dart';

@immutable
sealed class ScheduleState {}

final class ScheduleInitial extends ScheduleState {}

class ScheduleLoaded extends ScheduleState {
  final List<ScheduleModel> schedules;
  final bool hasMoreData;
  final int currentPage;
  final int totalPages;

  ScheduleLoaded({
    required this.schedules,
    required this.hasMoreData,
    required this.currentPage,
    required this.totalPages,
  });

  ScheduleLoaded copyWith({List<ScheduleModel>? schedules, bool? hasMoreData, int? currentPage, int? totalPages}) {
    return ScheduleLoaded(
      schedules: schedules ?? this.schedules,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class ScheduleError extends ScheduleState {
  final String message;

  ScheduleError(this.message);
}

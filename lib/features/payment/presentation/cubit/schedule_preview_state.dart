part of 'schedule_preview_cubit.dart';

sealed class SchedulePreviewState {}

final class SchedulePreviewInitial extends SchedulePreviewState {}

final class SchedulePreviewLoading extends SchedulePreviewState {}

final class SchedulePreviewLoaded extends SchedulePreviewState {
  SchedulePreviewLoaded(this.schedules);

  final List<ScheduleModel> schedules;
}

final class SchedulePreviewError extends SchedulePreviewState {
  SchedulePreviewError(this.message);

  final String message;
}

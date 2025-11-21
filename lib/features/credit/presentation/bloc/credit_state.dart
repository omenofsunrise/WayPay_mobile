import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/schedule_preview_model.dart';

abstract class CreditState {}

final class CreditInitial extends CreditState {}

final class CreditLoading extends CreditState {}

final class CreditLoaded extends CreditState {
  final List<CreditModel> credits;
  final bool hasMoreData;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  CreditLoaded({
    required this.credits,
    required this.hasMoreData,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  CreditLoaded copyWith({
    List<CreditModel>? credits,
    bool? hasMoreData,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) {
    return CreditLoaded(
      credits: credits ?? this.credits,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

final class CreditError extends CreditState {
  final String message;

  CreditError(this.message);
}

final class SchedulePreviewLoaded extends CreditState {
  final List<SchedulePreviewModel> schedulePreview;

  SchedulePreviewLoaded({required this.schedulePreview});
}

final class SchedulePreviewLoading extends CreditState {}

final class SchedulePreviewError extends CreditState {
  final String message;

  SchedulePreviewError(this.message);
}

final class CreditCreating extends CreditState {}

final class CreditCreated extends CreditState {
  final CreditModel createdCredit;

  CreditCreated({required this.createdCredit});
}

final class CreditCreationError extends CreditState {
  final String message;

  CreditCreationError(this.message);
}

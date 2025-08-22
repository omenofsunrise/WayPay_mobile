import 'package:waypay/features/credit/data/models/credit_model.dart';

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

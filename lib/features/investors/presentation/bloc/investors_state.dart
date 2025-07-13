part of 'investors_bloc.dart';

abstract class InvestorsState {}

class InvestorsInitial extends InvestorsState {}

class InvestorsLoading extends InvestorsState {}

class InvestorsLoaded extends InvestorsState {
  final List<InvestorsModel> investors;
  final bool hasMoreData;
  final int totalCount;
  final int perPage;
  final int currentPage;

  InvestorsLoaded({
    required this.investors,
    required this.hasMoreData,
    required this.totalCount,
    required this.perPage,
    required this.currentPage,
  });

  int get totalPages => (totalCount / perPage).ceil();
}

class InvestorsError extends InvestorsState {
  final String message;

  InvestorsError(this.message);
}

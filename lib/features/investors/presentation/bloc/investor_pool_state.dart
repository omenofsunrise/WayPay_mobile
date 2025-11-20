part of 'investor_pool_bloc.dart';

abstract class InvestorPoolState {}

class InvestorPoolInitial extends InvestorPoolState {}

class InvestorPoolLoading extends InvestorPoolState {}

class InvestorPoolLoaded extends InvestorPoolState {
  InvestorPoolLoaded({required this.items, required this.hasMore, required this.currentPage});

  final List<InvestorPoolModel> items;
  final bool hasMore;
  final int currentPage;
}

class InvestorPoolError extends InvestorPoolState {
  InvestorPoolError(this.message);
  final String message;
}

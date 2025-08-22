part of 'budget_expense_bloc.dart';

abstract class BudgetExpenseState {}

class BudgetExpenseInitial extends BudgetExpenseState {}

class BudgetExpenseLoading extends BudgetExpenseState {}

class BudgetExpenseLoaded extends BudgetExpenseState {
  final List<BudgetOutcomeModel> expenses;
  final int totalCount;
  final int currentPage;
  final int perPage;

  BudgetExpenseLoaded({
    required this.expenses,
    required this.totalCount,
    required this.currentPage,
    required this.perPage,
  });

  int get totalPages => (totalCount / perPage).ceil();
}

class BudgetExpenseError extends BudgetExpenseState {
  final String message;

  BudgetExpenseError(this.message);
}

part of 'budget_income_bloc.dart';

abstract class BudgetIncomeState {}

class BudgetIncomeInitial extends BudgetIncomeState {}

class BudgetIncomeLoading extends BudgetIncomeState {}

class BudgetIncomeLoaded extends BudgetIncomeState {
  final List<BudgetIncomeModel> incomes;
  final int totalCount;
  final int currentPage;
  final int perPage;

  BudgetIncomeLoaded({
    required this.incomes,
    required this.totalCount,
    required this.currentPage,
    required this.perPage,
  });

  int get totalPages => (totalCount / perPage).ceil();
}

class BudgetIncomeError extends BudgetIncomeState {
  final String message;

  BudgetIncomeError(this.message);
}

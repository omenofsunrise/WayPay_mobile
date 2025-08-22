part of 'budget_income_bloc.dart';

abstract class BudgetIncomeEvent {}

class LoadBudgetIncomeEvent extends BudgetIncomeEvent {
  final int? month;
  final int? year;
  final int? page;
  final int? pageSize;
  final String? sortDirection;

  LoadBudgetIncomeEvent({
    this.month,
    this.year,
    this.page,
    this.pageSize,
    this.sortDirection,
  });
}

class RefreshBudgetIncomeEvent extends BudgetIncomeEvent {
  final int? month;
  final int? year;

  RefreshBudgetIncomeEvent({this.month, this.year});
}

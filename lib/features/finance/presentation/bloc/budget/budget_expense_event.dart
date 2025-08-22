part of 'budget_expense_bloc.dart';

abstract class BudgetExpenseEvent {}

class LoadBudgetExpenseEvent extends BudgetExpenseEvent {
  final int? month;
  final int? year;
  final int? page;
  final int? pageSize;
  final String? sortDirection;

  LoadBudgetExpenseEvent({
    this.month,
    this.year,
    this.page,
    this.pageSize,
    this.sortDirection,
  });
}

class RefreshBudgetExpenseEvent extends BudgetExpenseEvent {
  final int? month;
  final int? year;

  RefreshBudgetExpenseEvent({this.month, this.year});
}

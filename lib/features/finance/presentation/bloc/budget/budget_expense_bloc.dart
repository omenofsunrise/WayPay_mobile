import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay/features/finance/data/models/budget_outcome_model.dart';

part 'budget_expense_event.dart';
part 'budget_expense_state.dart';

class BudgetExpenseBloc extends Bloc<BudgetExpenseEvent, BudgetExpenseState> {
  final _budgetDataSource = getIt<BudgetRemoteDataSource>();

  BudgetExpenseBloc() : super(BudgetExpenseInitial()) {
    on<LoadBudgetExpenseEvent>(_onLoadBudgetExpense);
  }

  Future<void> _onLoadBudgetExpense(
    LoadBudgetExpenseEvent event,
    Emitter<BudgetExpenseState> emit,
  ) async {
    emit(BudgetExpenseLoading());

    try {
      final validMonth =
          (event.month != null && event.month! >= 1 && event.month! <= 12)
          ? event.month
          : null;

      final response = await _budgetDataSource.getBudgetOutcomes(
        month: validMonth,
        year: event.year,
        page: event.page,
        pageSize: event.pageSize,
        sortDirection: event.sortDirection,
      );

      emit(
        BudgetExpenseLoaded(
          expenses: response.items,
          totalCount: response.totalCount,
          currentPage: response.page,
          perPage: response.pageSize,
        ),
      );
    } catch (e) {
      emit(BudgetExpenseError('Ошибка загрузки расходов: $e'));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay_mobile/features/finance/data/models/budget_income_model.dart';

part 'budget_income_event.dart';
part 'budget_income_state.dart';

class BudgetIncomeBloc extends Bloc<BudgetIncomeEvent, BudgetIncomeState> {
  final _budgetDataSource = getIt<BudgetRemoteDataSource>();

  BudgetIncomeBloc() : super(BudgetIncomeInitial()) {
    on<LoadBudgetIncomeEvent>(_onLoadBudgetIncome);
  }

  Future<void> _onLoadBudgetIncome(
    LoadBudgetIncomeEvent event,
    Emitter<BudgetIncomeState> emit,
  ) async {
    emit(BudgetIncomeLoading());

    try {
      final validMonth =
          (event.month != null && event.month! >= 1 && event.month! <= 12)
          ? event.month
          : null;

      // debug print request params
      // ignore: avoid_print
      print('[BudgetIncome][REQUEST] month=${event.month} year=${event.year} '
          'page=${event.page} pageSize=${event.pageSize} sort=${event.sortDirection}');

      final response = await _budgetDataSource.getBudgetIncomes(
        month: validMonth,
        year: event.year,
        page: event.page,
        pageSize: event.pageSize,
        sortDirection: event.sortDirection,
      );

      // debug print response metadata
      // ignore: avoid_print
      print('[BudgetIncome][RESPONSE] total=${response.totalCount} '
          'page=${response.page} pageSize=${response.pageSize}');
      for (final income in response.items) {
        print('[BudgetIncome][ITEM] id=${income.id} amount=${income.amount} '
            'comment=${income.comment} investor=${income.investorId} '
            'investorName=${income.investorName} date=${income.createdAt}');
      }

      emit(
        BudgetIncomeLoaded(
          incomes: response.items,
          totalCount: response.totalCount,
          currentPage: response.page,
          perPage: response.pageSize,
        ),
      );
    } catch (e) {
      emit(BudgetIncomeError('Ошибка загрузки приходов: $e'));
    }
  }
}

import 'package:waypay/features/finance/data/models/budget_income_response_model.dart';
import 'package:waypay/features/finance/data/models/budget_outcome_response_model.dart';
import 'package:waypay/features/finance/data/models/create_budget_income_dto.dart';
import 'package:waypay/features/finance/data/models/create_budget_outcome_dto.dart';

abstract class BudgetRemoteDataSource {
  Future<BudgetIncomeResponseModel> getBudgetIncomes({
    int? month,
    int? year,
    int? page,
    int? pageSize,
    String? sortDirection,
  });
  Future<BudgetOutcomeResponseModel> getBudgetOutcomes({
    int? month,
    int? year,
    int? page,
    int? pageSize,
    String? sortDirection,
  });
  Future<void> createBudgetIncome(CreateBudgetIncomeDto dto);
  Future<void> deleteBudgetIncome(int id);
  Future<void> createBudgetOutcome(CreateBudgetOutcomeDto dto);
  Future<void> deleteBudgetOutcome(int id);
}

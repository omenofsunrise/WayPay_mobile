import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay_mobile/features/finance/data/models/budget_income_response_model.dart';
import 'package:waypay_mobile/features/finance/data/models/budget_outcome_response_model.dart';
import 'package:waypay_mobile/features/finance/data/models/create_budget_income_dto.dart';
import 'package:waypay_mobile/features/finance/data/models/create_budget_outcome_dto.dart';

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final Dio dio;

  BudgetRemoteDataSourceImpl(this.dio);

  @override
  Future<BudgetIncomeResponseModel> getBudgetIncomes({
    int? month,
    int? year,
    int? page,
    int? pageSize,
    String? sortDirection,
  }) async {
    try {
      final now = DateTime.now();
      final queryParams = <String, dynamic>{};

      queryParams['month'] = month ?? now.month;
      queryParams['year'] = year ?? now.year;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (sortDirection != null && sortDirection.isNotEmpty) {
        queryParams['sortDirection'] = sortDirection;
      }

      final response = await dio.get(
        '/api/BudgetIncome',
        queryParameters: queryParams,
      );

      return BudgetIncomeResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при загрузке приходов бюджета: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<BudgetOutcomeResponseModel> getBudgetOutcomes({
    int? month,
    int? year,
    int? page,
    int? pageSize,
    String? sortDirection,
  }) async {
    try {
      final now = DateTime.now();
      final queryParams = <String, dynamic>{};

      queryParams['month'] = month ?? now.month;
      queryParams['year'] = year ?? now.year;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (sortDirection != null && sortDirection.isNotEmpty) {
        queryParams['sortDirection'] = sortDirection;
      }

      final response = await dio.get(
        '/api/BudgetOutcome',
        queryParameters: queryParams,
      );

      return BudgetOutcomeResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при загрузке расходов бюджета: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<void> createBudgetIncome(CreateBudgetIncomeDto dto) async {
    try {
      final response = await dio.post('/api/BudgetIncome', data: dto.toJson());

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка создания прихода: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при создании прихода: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<void> deleteBudgetIncome(int id) async {
    final response = await dio.delete('/api/BudgetIncome/$id');
    if (response.statusCode != 200) {
      throw Exception('Не удалось удалить приход');
    }
  }

  @override
  Future<void> createBudgetOutcome(CreateBudgetOutcomeDto dto) async {
    try {
      final response = await dio.post('/api/BudgetOutcome', data: dto.toJson());

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка создания прихода: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при создании прихода: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<void> deleteBudgetOutcome(int id) async {
    try {
      final response = await dio.delete('/api/BudgetOutcome/$id');

      if (response.statusCode != 200) {
        throw Exception('Не удалось удалить расход');
      }
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при удалении расхода: ${e.response?.data ?? e.message}',
      );
    }
  }
}

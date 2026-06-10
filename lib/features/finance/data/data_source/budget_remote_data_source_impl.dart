import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
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
        'BudgetIncome',
        queryParameters: queryParams,
      );

      return BudgetIncomeResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить приходы бюджета.',
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
        'BudgetOutcome',
        queryParameters: queryParams,
      );

      return BudgetOutcomeResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить расходы бюджета.',
      );
    }
  }

  @override
  Future<void> createBudgetIncome(CreateBudgetIncomeDto dto) async {
    try {
      // ignore: avoid_print
      print('[BudgetIncome][REQUEST] ${dto.toJson()}');
      final response = await dio.post('BudgetIncome', data: dto.toJson());

      // ignore: avoid_print
      print(
        '[BudgetIncome][RESPONSE] status=${response.statusCode} data=${response.data}',
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw const ApiError('Не удалось создать приход.');
      }
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[BudgetIncome][ERROR] ${e.response?.data ?? e.message}');
      throw mapApiError(e, fallback: 'Не удалось создать приход.');
    }
  }

  @override
  Future<void> deleteBudgetIncome(int id) async {
    final response = await dio.delete('BudgetIncome/$id');
    if (response.statusCode != 200) {
      throw const ApiError('Не удалось удалить приход.');
    }
  }

  @override
  Future<void> createBudgetOutcome(CreateBudgetOutcomeDto dto) async {
    try {
      final response = await dio.post('BudgetOutcome', data: dto.toJson());

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw const ApiError('Не удалось создать расход.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать расход.');
    }
  }

  @override
  Future<void> deleteBudgetOutcome(int id) async {
    try {
      final response = await dio.delete('BudgetOutcome/$id');

      if (response.statusCode != 200) {
        throw const ApiError('Не удалось удалить расход.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить расход.');
    }
  }
}

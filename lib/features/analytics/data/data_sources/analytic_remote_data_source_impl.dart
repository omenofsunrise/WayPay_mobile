import 'package:dio/dio.dart';
import 'package:waypay/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'package:waypay/features/analytics/data/models/analytic_items_response.dart';
import 'package:waypay/features/analytics/data/models/debt_dynamic_response.dart';
import 'package:waypay/features/analytics/data/models/graph_data.dart';
import 'package:waypay/features/analytics/data/models/sell_info_response.dart';

class AnalyticRemoteDataSourceImpl implements AnalyticRemoteDataSource {
  final Dio dio;

  AnalyticRemoteDataSourceImpl(this.dio);

  @override
  Future<AnalyticItemsResponse> getAnalyticItems({
    String? start,
    String? end,
    String? predefinedPeriod,
  }) async {
    try {
      final response = await dio.get(
        '/api/Analytic/items',
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (predefinedPeriod != null) 'predefinedPeriod': predefinedPeriod,
        },
      );

      return AnalyticItemsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Ошибка получения аналитики: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<SellInfoResponse> getSellInfo({
    String? start,
    String? end,
    String? predefinedPeriod,
  }) async {
    try {
      final response = await dio.get(
        '/api/Analytic/sell-info',
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (predefinedPeriod != null) 'predefinedPeriod': predefinedPeriod,
        },
      );

      return SellInfoResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Ошибка получения sell-info: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<GraphData> getInvestmentAmountDynamic({
    String? start,
    String? end,
    String? predefinedPeriod,
  }) async {
    try {
      final response = await dio.get(
        '/api/Analytic/InvestmentAmountDynamic',
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (predefinedPeriod != null) 'predefinedPeriod': predefinedPeriod,
        },
      );

      return GraphData.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Ошибка получения InvestmentAmountDynamic: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<DebtDynamicResponse> getDebtDynamic({
    String? start,
    String? end,
    String? predefinedPeriod,
  }) async {
    try {
      final response = await dio.get(
        '/api/Analytic/DebtDynamic',
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (predefinedPeriod != null) 'predefinedPeriod': predefinedPeriod,
        },
      );

      return DebtDynamicResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Ошибка получения DebtDynamic: ${e.response?.data ?? e.message}',
      );
    }
  }
}

import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'package:waypay_mobile/features/analytics/data/models/analytic_items_response.dart';
import 'package:waypay_mobile/features/analytics/data/models/debt_dynamic_response.dart';
import 'package:waypay_mobile/features/analytics/data/models/graph_data.dart';
import 'package:waypay_mobile/features/analytics/data/models/sell_info_response.dart';
import 'package:waypay_mobile/features/payment/data/models/payment_schedule_summary.dart';

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
        'Analytic/items',
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (predefinedPeriod != null) 'predefinedPeriod': predefinedPeriod,
        },
      );

      return AnalyticItemsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить аналитику.');
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
        'Analytic/sell-info',
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (predefinedPeriod != null) 'predefinedPeriod': predefinedPeriod,
        },
      );

      return SellInfoResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить информацию о продажах.',
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
        'Analytic/InvestmentAmountDynamic',
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (predefinedPeriod != null) 'predefinedPeriod': predefinedPeriod,
        },
      );

      return GraphData.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить динамику инвестиций.',
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
        'Analytic/DebtDynamic',
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
          if (predefinedPeriod != null) 'predefinedPeriod': predefinedPeriod,
        },
      );

      return DebtDynamicResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить динамику задолженности.',
      );
    }
  }

  @override
  Future<List<PaymentScheduleSummary>> getPaymentSchedules({int? year}) async {
    try {
      final response = await dio.get(
        'Analytic/schedules',
        queryParameters: {if (year != null) 'year': year},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map(
              (item) =>
                  PaymentScheduleSummary.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить аналитику платежей.',
      );
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_response_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/schedule_preview_model.dart';

class CreditRemoteDataSourceImpl implements CreditRemoteDataSource {
  final Dio dio;

  CreditRemoteDataSourceImpl(this.dio);
  @override
  Future<CreditResponseModel> getCredits(GetCreditsQuery query) async {
    try {
      final response = await dio.get(
        'Credit',
        queryParameters: query.toQueryParams(),
      );

      if (response.data is Map<String, dynamic>) {
        final creditResponse = CreditResponseModel.fromJson(response.data);

        if (query.clientId != null) {
          for (final credit in creditResponse.items) {
            debugPrint(
              'Client ${query.clientId} -> credit ${credit.id}: '
              'paid=${credit.payed}, rest=${credit.rest}, debt=${credit.debt}',
            );
          }
          if (creditResponse.items.isEmpty) {
            debugPrint('Client ${query.clientId} has no credits in history.');
          }
        }

        return creditResponse;
      } else {
        throw Exception('Неожиданный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки договоров: ${e.message}');
    }
  }

  @override
  Future<CreditModel> getCreditById(int id) async {
    try {
      final response = await dio.get('Credit/$id');

      if (response.data is Map<String, dynamic>) {
        return CreditModel.fromJson(response.data);
      } else {
        throw Exception('Неожиданный формат ответа');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки договора по id: ${e.message}');
    }
  }

  @override
  Future<void> toggleFavourite(int creditId) async {
    try {
      final response = await dio.put('Credit/$creditId/toggle-favourite');

      if (response.statusCode != 200) {
        throw Exception('Ошибка при обновлении избранного');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка при обновлении избранного: ${e.message}');
    }
  }

  @override
  Future<void> deleteCreditById(int id) async {
    try {
      final response = await dio.delete('Credit/$id');
      debugPrint(
        '📬 Ответ от сервера: ${response.statusCode} ${response.statusMessage}',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Ошибка при удалении договора');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка при удалении договора: ${e.message}');
    }
  }

  @override
  Future<CreditResponseModel> getCreditsByInvestorId(
    int investorId,
    GetCreditsQuery query,
  ) async {
    try {
      final response = await dio.get(
        'Credit/investor/$investorId',
        queryParameters: query.toQueryParams(),
      );
      return CreditResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки кредитов инвестора: ${e.message}');
    }
  }

  @override
  Future createCredit(CreateCreditRequest request) async {
    try {
      await dio.post('Credit', data: request.toJson());
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final errorMessage =
              errorData['title'] ?? errorData['message'] ?? 'Ошибка валидации';
          throw Exception(errorMessage);
        }
      }
      throw Exception('Ошибка создания договора: ${e.message}');
    }
  }

  @override
  Future<List<SchedulePreviewModel>> getSchedulePreview({
    required double totalAmount,
    required double firstPayment,
    required int termMonths,
    required int paymentDay,
    required bool currentMonthStart,
    required bool nextMonthStart,
  }) async {
    try {
      final requestBody = {
        'totalAmount': totalAmount,
        'firstPayment': firstPayment,
        'termMonths': termMonths,
        'paymentDay': paymentDay,
        'currentMonthStart': currentMonthStart,
        'nextMonthStart': nextMonthStart,
      };

      final response = await dio.post('Schedule/preview', data: requestBody);

      if (response.data is List) {
        return (response.data as List)
            .map((item) => SchedulePreviewModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Неожиданный формат ответа для preview платежей');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки preview платежей: ${e.message}');
    }
  }
}

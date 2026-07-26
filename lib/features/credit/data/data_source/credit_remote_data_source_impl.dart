import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
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
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить договоры.');
    }
  }

  @override
  Future<CreditModel> getCreditById(int id) async {
    try {
      final response = await dio.get('Credit/$id');

      if (response.data is Map<String, dynamic>) {
        return CreditModel.fromJson(response.data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить договор.');
    }
  }

  @override
  Future<List<CreditModel>> getCreditsByClientId(int clientId) async {
    try {
      final response = await dio.get('Credit/list/$clientId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return CreditResponseModel.fromJson(data).items;
      }
      if (data is List) {
        return data
            .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить договоры клиента.');
    }
  }

  @override
  Future<void> toggleFavourite(int creditId) async {
    try {
      final response = await dio.put('Credit/$creditId/toggle-favourite');

      if (response.statusCode != 200) {
        throw const ApiError('Не удалось обновить избранное.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить избранное.');
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
        throw const ApiError('Не удалось удалить договор.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить договор.');
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
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить договоры инвестора.',
      );
    }
  }

  @override
  Future createCredit(CreateCreditRequest request) async {
    try {
      await dio.post('Credit', data: request.toJson());
    } on DioException catch (e) {
      throw ApiError(_formatCreateCreditError(e));
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
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить предпросмотр платежей.',
      );
    }
  }

  String? _extractServerError(DioException e) {
    final data = e.response?.data;
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    if (data is List) {
      final joined = data.map((e) => e.toString()).join('\n');
      return joined.trim().isNotEmpty ? joined : null;
    }
    if (data is Map<String, dynamic>) {
      final title = data['title']?.toString();
      final detail = data['message']?.toString() ?? data['detail']?.toString();
      final errors = data['errors'];
      String formattedErrors = '';
      if (errors is Map<String, dynamic>) {
        formattedErrors = errors.entries
            .map((entry) {
              final value = entry.value;
              if (value is List) {
                return '${entry.key}: ${value.join(', ')}';
              }
              return '${entry.key}: ${value.toString()}';
            })
            .join('\n');
      }
      return [
        title,
        detail,
        formattedErrors.isNotEmpty ? formattedErrors : null,
      ].whereType<String>().join('\n');
    }
    return null;
  }

  String _formatCreateCreditError(DioException e) {
    final statusCode = e.response?.statusCode;
    final serverMessage = _extractServerError(e);
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return statusCode == null
          ? serverMessage
          : '$serverMessage (Код ошибки: $statusCode)';
    }

    final responseData = e.response?.data;
    if (responseData != null) {
      final text = _truncate(responseData.toString(), 500);
      return statusCode == null
          ? 'Ошибка создания договора. Ответ сервера: $text'
          : 'Ошибка создания договора. Ответ сервера: $text (Код ошибки: $statusCode)';
    }

    return _mapGenericCreateError(statusCode);
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  String _mapGenericCreateError(int? statusCode) {
    final baseText =
        'Не удалось создать договор. Проверьте данные и попробуйте снова.';
    if (statusCode == null) {
      return baseText;
    }
    return '$baseText (Код ошибки: $statusCode)';
  }
}

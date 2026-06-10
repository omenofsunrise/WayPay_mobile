import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/get_payment_query.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';

class PaymentRemoteDataSourcesImpl implements PaymentRemoteDataSources {
  final Dio dio;

  PaymentRemoteDataSourcesImpl(this.dio);
  @override
  Future<PaymentListResponseModel> getPayment(GetPaymentsQuery query) async {
    try {
      final response = await dio.get(
        'Payment',
        queryParameters: query.toQueryParams(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return PaymentListResponseModel.fromJson(data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить журнал платежей.');
    }
  }

  @override
  Future<PaymentListResponseModel> getPaymentsByCredit({
    required int creditId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        'Payment/by-credit/$creditId',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaymentListResponseModel.fromJson(data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить платежи по договору.',
      );
    }
  }

  @override
  Future<PaymentItemModel> getPaymentById(int id) async {
    try {
      final response = await dio.get('Payment/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaymentItemModel.fromJson(data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить платёж.');
    }
  }

  @override
  Future<void> createPayment({
    required int creditId,
    required double paymentAmount,
    required DateTime datePayment,
    required PaymentType type,
    int? bankCardId,
  }) async {
    try {
      final payload = {
        'creditId': creditId,
        'paymentAmount': paymentAmount,
        'datePayment': datePayment.toIso8601String(),
        'type': paymentTypeToString(type),
      };
      if (bankCardId != null) {
        payload['bankCardId'] = bankCardId;
      }

      await dio.post('Payment', data: payload);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать платёж.');
    }
  }

  @override
  Future<void> confirmPayment(int id) async {
    try {
      await dio.patch('Payment/$id/confirm');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось подтвердить платёж.');
    }
  }

  @override
  Future<void> deletePayment(int id) async {
    try {
      await dio.delete('Payment/$id');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить платёж.');
    }
  }
}

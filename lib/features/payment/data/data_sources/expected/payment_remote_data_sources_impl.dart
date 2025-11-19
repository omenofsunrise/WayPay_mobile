import 'package:dio/dio.dart';
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
        throw Exception('Не тот формат');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения журнала платежей: ${e.message}');
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
        throw Exception('Не тот формат');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения журнала платежей по id: ${e.message}');
    }
  }

  @override
  Future<void> createPayment({
    required int creditId,
    required double paymentAmount,
    required DateTime datePayment,
    required PaymentType type,
  }) async {
    try {
      final payload = {
        'creditId': creditId,
        'paymentAmount': paymentAmount,
        'datePayment': datePayment.toIso8601String(),
        'type': paymentTypeToString(type),
      };

      await dio.post('Payment', data: payload);
    } on DioException catch (e) {
      throw Exception('Ошибка при создании платежа: ${e.message}');
    }
  }

  @override
  Future<void> confirmPayment(int id) async {
    try {
      await dio.patch('Payment/$id/confirm');
    } on DioException catch (e) {
      throw Exception('Ошибка подтверждения платежа: ${e.message}');
    }
  }

  @override
  Future<void> deletePayment(int id) async {
    try {
      await dio.delete('Payment/$id');
    } on DioException catch (e) {
      throw Exception('Ошибка при удалении платежа: ${e.message}');
    }
  }
}

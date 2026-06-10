import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/bank_card/data/data_sources/bank_card_remote_data_source.dart';
import 'package:waypay_mobile/features/bank_card/data/models/bank_card_model.dart';
import 'package:waypay_mobile/features/bank_card/data/models/bank_card_paged_result.dart';
import 'package:waypay_mobile/features/bank_card/data/models/bank_card_request.dart';

class BankCardRemoteDataSourceImpl implements BankCardRemoteDataSource {
  final Dio dio;

  BankCardRemoteDataSourceImpl(this.dio);

  @override
  Future<BankCardPagedResult> getBankCards({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        'BankCard',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return BankCardPagedResult.fromJson(data);
      }
      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить карты.');
    }
  }

  @override
  Future<BankCardModel> createBankCard(BankCardRequest request) async {
    try {
      final response = await dio.post('BankCard', data: request.toJson());
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return BankCardModel.fromJson(data);
      }
      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать карту.');
    }
  }

  @override
  Future<BankCardModel> updateBankCard(
    int id,
    BankCardRequest request,
  ) async {
    try {
      final response = await dio.put('BankCard/$id', data: request.toJson());
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return BankCardModel.fromJson(data);
      }
      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить карту.');
    }
  }

  @override
  Future<void> deleteBankCard(int id) async {
    try {
      await dio.delete('BankCard/$id');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить карту.');
    }
  }
}

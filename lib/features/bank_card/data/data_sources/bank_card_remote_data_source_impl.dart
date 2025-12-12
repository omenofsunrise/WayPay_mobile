import 'package:dio/dio.dart';
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
      throw Exception('Неверный формат ответа при получении карт');
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? 'Ошибка загрузки карт');
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
      throw Exception('Неверный формат ответа при создании карты');
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? 'Ошибка создания карты');
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
      throw Exception('Неверный формат ответа при обновлении карты');
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? 'Ошибка обновления карты');
    }
  }

  @override
  Future<void> deleteBankCard(int id) async {
    try {
      await dio.delete('BankCard/$id');
    } on DioException catch (e) {
      throw Exception(_extractServerMessage(e) ?? 'Ошибка удаления карты');
    }
  }

  String? _extractServerMessage(DioException e) {
    final data = e.response?.data;
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final title = data['title']?.toString();
      final detail = data['detail']?.toString() ?? data['message']?.toString();
      final errors = data['errors'];
      String? formattedErrors;
      if (errors is Map<String, dynamic>) {
        formattedErrors = errors.entries
            .map(
              (entry) =>
                  '${entry.key}: ${(entry.value as List).join(', ')}',
            )
            .join('\n');
      }
      return [
        title,
        detail,
        formattedErrors,
      ].whereType<String>().where((value) => value.trim().isNotEmpty).join('\n');
    }
    return e.message;
  }
}

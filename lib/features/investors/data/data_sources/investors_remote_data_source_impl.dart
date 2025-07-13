import 'package:dio/dio.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/data/models/investor_payout_request.dart';
import 'package:waypay/features/investors/data/models/investor_payout_response.dart';
import 'package:waypay/features/investors/data/models/investors_model.dart';
import '../models/investors_response_model.dart';

class InvestorRemoteDataSourceImpl implements InvestorsRemoteDataSource {
  final Dio dio;

  InvestorRemoteDataSourceImpl(this.dio);

  @override
  Future<InvestorsResponseModel> getInvestors({
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortDirection,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortDirection != null && sortDirection.isNotEmpty) {
        queryParams['sortDirection'] = sortDirection;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      print('🌐 Запрос к API: /api/Investor');
      print('📋 Параметры: $queryParams');

      final response = await dio.get(
        '/api/Investor',
        queryParameters: queryParams,
      );

      print('✅ Ответ API: ${response.statusCode}');
      print('📄 Данные: ${response.data}');

      return InvestorsResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Сообщение: ${e.message}');
      print('❌ Ответ: ${e.response?.data}');
      print('❌ Статус код: ${e.response?.statusCode}');

      if (e.response?.statusCode == 401) {
        throw Exception('Ошибка авторизации: ${e.response?.data}');
      } else if (e.response?.statusCode == 404) {
        throw Exception('API не найден: /api/Investor');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Ошибка сервера: ${e.response?.data}');
      } else {
        throw Exception('Ошибка сети: ${e.message}');
      }
    } catch (e) {
      print('❌ Неизвестная ошибка: $e');
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  @override
  Future<InvestorsModel> getInvestorById(int id) async {
    try {
      final response = await dio.get('/api/Investor/$id');

      print('✅ Загружен инвестор по ID: ${response.data}');

      return InvestorsModel.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Ошибка при загрузке инвестора по ID: ${e.response?.data}');
      throw Exception('Не удалось загрузить данные инвестора');
    }
  }

  @override
  Future<void> createInvestor({
    required String nickname,
    required String fullName,
    required String? phoneNumber,
    required int investorPie,
    required double investmentAmount,
  }) async {
    try {
      final payload = {
        'nickname': nickname,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'investorPie': investorPie,
        'investmentAmount': investmentAmount,
      };

      print('🌐 Отправляем POST /api/Investor');
      print('📦 Payload: $payload');

      final response = await dio.post('/api/Investor', data: payload);

      print('✅ Инвестор создан: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Ошибка создания инвестора: ${e.response?.data}');
      throw Exception('Не удалось создать инвестора');
    }
  }

  @override
  Future<void> deleteInvestor(int id) async {
    try {
      print('🌐 Отправляем DELETE /api/Investor/$id');
      final response = await dio.delete('/api/Investor/$id');
      print('✅ Инвестор удалён: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Ошибка удаления инвестора: ${e.response?.data}');
      throw Exception('Не удалось удалить инвестора');
    }
  }

  @override
  Future<void> updateInvestor({
    required int id,
    required String nickname,
    required String fullName,
    String? phoneNumber,
    required int investorPie,
  }) async {
    try {
      final payload = {
        'nickname': nickname,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'investorPie': investorPie,
      };

      print('🌐 PUT /api/Investor/$id');
      print('📦 Payload: $payload');

      final response = await dio.put('/api/Investor/$id', data: payload);

      print('✅ Инвестор обновлён: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Ошибка обновления инвестора: ${e.response?.data}');
      throw Exception('Не удалось обновить инвестора');
    }
  }

  @override
  Future<void> addInvestment({required int id, required double amount}) async {
    try {
      final payload = {'amount': amount};

      print('🌐 PUT /api/Investor/$id/add-investment');
      print('📦 Payload: $payload');

      final response = await dio.put(
        '/api/Investor/$id/add-investment',
        data: payload,
      );

      print('✅ Инвестиция добавлена: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Ошибка добавления инвестиций: ${e.response?.data}');
      throw Exception('Не удалось добавить инвестицию');
    }
  }

  @override
  Future<void> toggleBlockInvestor(int id) async {
    try {
      print('🌐 PATCH /api/Investor/toggle-block/$id');
      final response = await dio.patch('/api/Investor/toggle-block/$id');
      print('✅ Статус блокировки изменён: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Ошибка смены блокировки: ${e.response?.data}');
      throw Exception('Не удалось сменить статус блокировки инвестора');
    }
  }

  @override
  Future<void> clearInvestor(int id) async {
    try {
      await dio.patch('/api/Investor/clear/$id');
    } on DioException catch (e) {
      throw Exception(
        'Не удалось аннулировать инвестора.\n${e.response?.data}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getInvestorReport(int id) async {
    try {
      final response = await dio.get('/api/Investor/report/$id');

      print('✅ Отчет инвестора получен: ${response.data}');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Ошибка получения отчета инвестора: ${e.response?.data}');
      throw Exception('Ошибка получения отчета инвестора: ${e.message}');
    }
  }

  @override
  Future<InvestorPayoutResponse> createInvestorPayout({
    required int investorId,
    required double amount,
  }) async {
    try {
      final response = await dio.post(
        '/api/InvestorPayouts',
        data: InvestorPayoutRequest(
          investorId: investorId,
          amount: amount,
        ).toJson(),
      );

      return InvestorPayoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Ошибка создания выплаты: ${e.response?.data}');
      throw Exception('Ошибка выплаты: ${e.message}');
    }
  }
}

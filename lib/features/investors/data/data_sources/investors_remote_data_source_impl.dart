import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_request.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_response.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import '../models/investors_response_model.dart';
import '../models/investor_pool_response_model.dart';

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

      final response = await dio.get(
        'Investor',
        queryParameters: queryParams,
      );

      return InvestorsResponseModel.fromJson(response.data);
    } on DioException catch (e) {
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
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  @override
  Future<InvestorPoolResponseModel> getInvestorPools({
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortDirection,
    String? search,
  }) async {
    try {
      // ignore: avoid_print
      print(
        '🔍 Запрос списка пулов: page=${page ?? 1}, pageSize=${pageSize ?? 20}, '
        'sortBy=${sortBy ?? 'name'}, sortDirection=${sortDirection ?? 'asc'}, search=$search',
      );
      final queryParams = <String, dynamic>{
        'page': page ?? 1,
        'pageSize': pageSize ?? 20,
        'sortBy': sortBy ?? 'name',
        'sortDirection': sortDirection ?? 'asc',
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        queryParams['name'] = search;
      }
      final response = await dio.get(
        'InvestorPool',
        queryParameters: queryParams,
      );
      // ignore: avoid_print
      print(
        '✅ Ответ списка пулов: status=${response.statusCode}, items=${(response.data['items'] as List?)?.length ?? 0}',
      );
      // ignore: avoid_print
      print('📦 Данные списка пулов: ${response.data}');
      return InvestorPoolResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      // ignore: avoid_print
      print('❌ Ошибка списка пулов: ${e.response?.data ?? e.message}');
      throw Exception('Ошибка загрузки пула инвесторов: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Future<InvestorsModel> getInvestorById(int id) async {
    try {
      final response = await dio.get('Investor/$id');

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

      final response = await dio.post('Investor', data: payload);

      print('✅ Инвестор создан: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Ошибка создания инвестора: ${e.response?.data}');
      throw Exception('Не удалось создать инвестора');
    }
  }

  @override
  Future<void> deleteInvestor(int id) async {
    try {
      final response = await dio.delete('Investor/$id');
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

      final response = await dio.put('Investor/$id', data: payload);

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

      final response = await dio.put(
        'Investor/$id/add-investment',
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
      final response = await dio.patch('Investor/toggle-block/$id');
      print('✅ Статус блокировки изменён: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Ошибка смены блокировки: ${e.response?.data}');
      throw Exception('Не удалось сменить статус блокировки инвестора');
    }
  }

  @override
  Future<void> clearInvestor(int id) async {
    try {
      await dio.patch('Investor/clear/$id');
    } on DioException catch (e) {
      throw Exception(
        'Не удалось аннулировать инвестора.\n${e.response?.data}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getInvestorReport(int id) async {
    try {
      final response = await dio.get('Investor/report/$id');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Ошибка получения отчета инвестора: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> getInvestorPoolReport(int id) async {
    try {
      // Log id to help diagnose server-side errors
      // ignore: avoid_print
      print('🔍 Запрос отчета пула для ID: $id');
      final response = await dio.get('InvestorPool/report/$id');
      // ignore: avoid_print
      print('✅ Ответ отчета пула $id: ${response.statusCode}');
      // ignore: avoid_print
      print('📦 Данные отчета пула $id: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('❌ Ошибка отчета пула $id: ${e.response?.data ?? e.message}');
      throw Exception('Ошибка получения отчета пула инвесторов: ${e.message}');
    }
  }

  @override
  Future<InvestorPayoutResponse> createInvestorPayout({
    required int investorId,
    required double amount,
  }) async {
    try {
      final response = await dio.post(
        'InvestorPayouts',
        data: InvestorPayoutRequest(
          investorId: investorId,
          amount: amount,
        ).toJson(),
      );

      return InvestorPayoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Ошибка выплаты: ${e.message}');
    }
  }

  @override
  Future<List<InvestorPayoutModel>> getInvestorPayoutsByInvestorId(
    int investorId,
  ) async {
    try {
      final response = await dio.get(
        'InvestorPayouts/investor/$investorId',
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => InvestorPayoutModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Неожиданный формат ответа API');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения выплат инвестора: ${e.message}');
    }
  }
}

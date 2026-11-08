import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_cash_position_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_contribution_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/data/models/move_cash_position_request.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_request.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_response.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/data/models/reinvestment_model.dart';
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
    int? poolId,
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
      if (poolId != null) {
        queryParams['poolId'] = poolId;
      }

      final response = await dio.get('Investor', queryParameters: queryParams);

      return InvestorsResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить инвесторов.');
    } catch (e) {
      if (e is ApiError) rethrow;
      throw mapApiError(e, fallback: 'Не удалось загрузить инвесторов.');
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
      throw mapApiError(e, fallback: 'Не удалось загрузить пулы инвесторов.');
    }
  }

  @override
  Future<InvestorsModel> getInvestorById(int id) async {
    try {
      final response = await dio.get('Investor/$id');

      debugPrint('✅ Загружен инвестор по ID: ${response.data}');

      return InvestorsModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ Ошибка при загрузке инвестора по ID: ${e.response?.data}');
      throw mapApiError(e, fallback: 'Не удалось загрузить инвестора.');
    }
  }

  @override
  Future<void> createInvestor({
    required String nickname,
    required String fullName,
    required String? phoneNumber,
    required int investorPie,
    required double investmentAmount,
    required DateTime activeUntil,
    int? poolId,
  }) async {
    try {
      final payload = {
        'nickname': nickname,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'investorPie': investorPie,
        'investmentAmount': investmentAmount,
        'activeUntil': activeUntil.toUtc().toIso8601String(),
        if (poolId != null) 'poolId': poolId,
      };

      final response = await dio.post('Investor', data: payload);

      debugPrint('✅ Инвестор создан: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ Ошибка создания инвестора: ${e.response?.data}');
      throw mapApiError(e, fallback: 'Не удалось создать инвестора.');
    }
  }

  @override
  Future<void> deleteInvestor(int id) async {
    try {
      final response = await dio.delete('Investor/$id');
      debugPrint('✅ Инвестор удалён: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ Ошибка удаления инвестора: ${e.response?.data}');
      throw mapApiError(e, fallback: 'Не удалось удалить инвестора.');
    }
  }

  @override
  Future<void> updateInvestor({
    required int id,
    required String nickname,
    required String fullName,
    String? phoneNumber,
    required int investorPie,
    required DateTime activeUntil,
  }) async {
    try {
      final payload = {
        'nickname': nickname,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'investorPie': investorPie,
        'activeUntil': activeUntil.toUtc().toIso8601String(),
      };

      final response = await dio.put('Investor/$id', data: payload);

      debugPrint('✅ Инвестор обновлён: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ Ошибка обновления инвестора: ${e.response?.data}');
      throw mapApiError(e, fallback: 'Не удалось обновить инвестора.');
    }
  }

  @override
  Future<void> addInvestment({
    required int id,
    required double amount,
    DateTime? date,
  }) async {
    try {
      final payload = {
        'amount': amount,
        'date': (date ?? DateTime.now()).toUtc().toIso8601String(),
      };

      final response = await dio.put(
        'Investor/$id/add-investment',
        data: payload,
      );

      debugPrint('✅ Инвестиция добавлена: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ Ошибка добавления инвестиций: ${e.response?.data}');
      throw mapApiError(e, fallback: 'Не удалось добавить инвестицию.');
    }
  }

  @override
  Future<void> toggleBlockInvestor(int id) async {
    try {
      final response = await dio.patch('Investor/toggle-block/$id');
      debugPrint('✅ Статус блокировки изменён: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ Ошибка смены блокировки: ${e.response?.data}');
      throw mapApiError(e, fallback: 'Не удалось изменить статус блокировки.');
    }
  }

  @override
  Future<void> clearInvestor(int id) async {
    try {
      await dio.patch('Investor/clear/$id');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось аннулировать инвестора.');
    }
  }

  @override
  Future<Map<String, dynamic>> getInvestorReport(int id) async {
    try {
      final response = await dio.get('Investor/report/$id');

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить отчёт инвестора.');
    }
  }

  @override
  Future<Map<String, dynamic>> getInvestorAgreement(int id) async {
    try {
      final response = await dio.get('Investor/agreement/$id');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить договор инвестора.');
    }
  }

  @override
  Future<Map<String, dynamic>> getDeletedInvestorInfo() async {
    try {
      final response = await dio.get('Investor/deleted/info');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить данные удалённых инвесторов.',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> createInvestorShareLink(
    int investorId, {
    int? minutes,
  }) async {
    try {
      final response = await dio.post(
        'Investor/report/temporary-token',
        data: {
          'investorId': investorId,
          if (minutes != null) 'minutes': minutes,
        },
      );
      if (response.data is String) {
        final raw = response.data as String;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {
          // Некоторые версии API возвращают только токен как text/plain.
        }
        return {'token': raw};
      }
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать временную ссылку.');
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
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить отчёт пула инвесторов.',
      );
    }
  }

  @override
  Future<InvestorPayoutResponse> createInvestorPayout({
    required int investorId,
    required double amount,
    String? payoutSource,
  }) async {
    try {
      final response = await dio.post(
        'InvestorPayouts',
        data: InvestorPayoutRequest(
          investorId: investorId,
          amount: amount,
          payoutSource: payoutSource,
        ).toJson(),
      );

      return InvestorPayoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать выплату.');
    }
  }

  @override
  Future<List<InvestorPayoutModel>> getInvestorPayoutsByPoolId(
    int poolId,
  ) async {
    try {
      final response = await dio.get('InvestorPayouts/pool/$poolId');
      return (response.data as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                InvestorPayoutModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить выплаты пула.');
    }
  }

  @override
  Future<void> deleteInvestorPayout(int id) async {
    try {
      await dio.delete('InvestorPayouts/$id');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить выплату.');
    }
  }

  @override
  Future<InvestorContributionsPage> getInvestorContributions({
    int? investorId,
    int? poolId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        'InvestmentContribution/',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (investorId != null) 'investorId': investorId,
          if (poolId != null) 'poolId': poolId,
        },
      );
      return InvestorContributionsPage.fromJson(response.data);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить инвестиции.');
    }
  }

  @override
  Future<void> updateInvestmentContribution({
    required int id,
    required double amount,
    required DateTime date,
  }) async {
    try {
      await dio.put(
        'InvestmentContribution/$id',
        data: {'amount': amount, 'date': date.toUtc().toIso8601String()},
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось изменить инвестицию.');
    }
  }

  @override
  Future<void> makeInvestmentContributionAction(int id, String action) async {
    try {
      await dio.patch('InvestmentContribution/action/$id', data: action);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось изменить инвестицию.');
    }
  }

  @override
  Future<InvestorPoolModel> createInvestorPool(String name) async {
    try {
      final response = await dio.post('InvestorPool', data: {'name': name});
      return InvestorPoolModel.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать пул.');
    }
  }

  @override
  Future<void> updateInvestorPoolName(int id, String name) async {
    try {
      await dio.put('InvestorPool/$id/name', data: name);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось переименовать пул.');
    }
  }

  @override
  Future<void> deleteInvestorPool(int id) async {
    try {
      await dio.delete('InvestorPool/$id');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить пул.');
    }
  }

  @override
  Future<void> reinvestInvestorPool(int id) async {
    try {
      await dio.patch('InvestorPool/reinvest/$id');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось выполнить реинвестицию.');
    }
  }

  @override
  Future<List<ReinvestmentModel>> getReinvestments(
    int poolId, {
    int page = 1,
    int pageSize = 20,
    int? investorId,
  }) async {
    try {
      final response = await dio.get(
        'InvestorPool/$poolId/reinvestments',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (investorId != null) 'investorId': investorId,
        },
      );
      final data = response.data;
      final items = data is List
          ? data
          : ((data as Map?)?['items'] as List? ?? const []);
      return items
          .whereType<Map>()
          .map(
            (item) =>
                ReinvestmentModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить реинвестиции.');
    }
  }

  @override
  Future<List<InvestorPayoutModel>> getInvestorPayoutsByInvestorId(
    int investorId,
  ) async {
    try {
      final response = await dio.get('InvestorPayouts/investor/$investorId');

      if (response.data is List) {
        return (response.data as List)
            .map((e) => InvestorPayoutModel.fromJson(e))
            .toList();
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить выплаты инвестора.');
    }
  }

  @override
  Future<InvestorCashPositionHistoryResponse> getCashPositionHistory(
    int investorId, {
    int page = 1,
  }) async {
    try {
      final response = await dio.get(
        'Investor/$investorId/cash/positions/history',
        queryParameters: {'page': page},
      );

      final data = response.data;

      if (data == null) {
        return const InvestorCashPositionHistoryResponse(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 10,
        );
      }

      if (data is List) {
        final items = data
            .map(
              (e) =>
                  InvestorCashPositionModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        return InvestorCashPositionHistoryResponse(
          items: items,
          totalCount: items.length,
          page: page,
          pageSize: items.isEmpty ? 10 : items.length,
        );
      }

      if (data is Map<String, dynamic>) {
        return InvestorCashPositionHistoryResponse.fromJson(data);
      }

      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить историю кассы.');
    }
  }

  @override
  Future<void> moveCashPosition(MoveCashPositionRequest request) async {
    try {
      await dio.post('Investor/cash/positions/history', data: request.toJson());
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось перевести кассу инвестора.');
    }
  }

  @override
  Future<void> deleteCashPosition(int id) async {
    try {
      await dio.delete('Investor/cash/position/history/$id');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить запись из истории.');
    }
  }
}

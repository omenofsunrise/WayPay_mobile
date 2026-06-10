import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/home/data/data_source/home_remote_data_source.dart';
import 'package:waypay_mobile/features/home/data/models/employee_model.dart';
import 'package:waypay_mobile/features/home/data/models/main_client_stats_model.dart';

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSourceImpl(this.dio);

  @override
  Future<EmployeeModel> getEmployeeData() async {
    try {
      final response = await dio.get('Dashboard/employee');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final employee = EmployeeModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          final stats = await _fetchMainClientStats();
          return employee.copyWith(
            clientsCount: stats.clientsCount,
            creditApplicationCount: stats.creditApplicationsCount,
            queuesCount: stats.queuesCount,
            creditsCount: stats.creditsCount,
            blacklistCount: stats.blacklistCount,
          );
        } else {
          throw const ApiError('Сервер вернул некорректный ответ.');
        }
      } else {
        throw const ApiError('Сервер временно недоступен. Попробуйте позже.');
      }
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить данные сотрудника.',
      );
    } catch (e) {
      if (e is ApiError) rethrow;
      throw mapApiError(e, fallback: 'Не удалось загрузить данные сотрудника.');
    }
  }

  Future<MainClientStatsModel> _fetchMainClientStats() async {
    const query = '''
      query MainClientStats {
        getBlacklistCount
        getClientsCount
        getCreditApplicationsCount
        getCreditsCount
        getQueuesCount
      }
    ''';

    try {
      final response = await dio.post(
        ApiConfig.graphqlUrl,
        data: {'query': query, 'operationName': 'MainClientStats'},
      );

      if (response.statusCode != 200) {
        throw const ApiError('Сервер временно недоступен. Попробуйте позже.');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }

      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final firstError = errors.first;
        final message = firstError is Map<String, dynamic>
            ? firstError['message']?.toString()
            : firstError.toString();
        throw ApiError(message ?? 'Не удалось загрузить статистику.');
      }

      final statsPayload = data['data'];
      if (statsPayload is! Map<String, dynamic>) {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }

      return MainClientStatsModel.fromJson(statsPayload);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить статистику.');
    }
  }
}

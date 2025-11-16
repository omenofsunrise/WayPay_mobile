import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/home/data/data_source/home_remote_data_source.dart';
import 'package:waypay_mobile/features/home/data/models/employee_model.dart';
import 'package:waypay_mobile/features/home/data/models/main_client_stats_model.dart';

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSourceImpl(this.dio);

  @override
  Future<EmployeeModel> getEmployeeData() async {
    try {
      final response = await dio.get('/employee');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final employee =
              EmployeeModel.fromJson(response.data as Map<String, dynamic>);
          final stats = await _fetchMainClientStats();
          return employee.copyWith(
            clientsCount: stats.clientsCount,
            creditApplicationCount: stats.creditApplicationsCount,
            queuesCount: stats.queuesCount,
            creditsCount: stats.creditsCount,
            blacklistCount: stats.blacklistCount,
            blackCatalogCount: stats.blackCatalogCount,
          );
        } else {
          throw Exception('Неожиданный формат ответа: ожидался JSON объект');
        }
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Ошибка авторизации');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Данные сотрудника не найдены');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Таймаут соединения');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Таймаут получения данных');
      } else {
        throw Exception('Ошибка загрузки данных сотрудника: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  Future<MainClientStatsModel> _fetchMainClientStats() async {
    const query = '''
      query MainClientStats {
        getBlackCatalogCount
        getBlacklistCount
        getClientsCount
        getCreditApplicationsCount
        getCreditsCount
        getQueuesCount
      }
    ''';

    try {
      final response = await dio.post(
        '/graphql',
        data: {
          'query': query,
          'operationName': 'MainClientStats',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка GraphQL: ${response.statusCode}');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Неожиданный формат GraphQL ответа');
      }

      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final firstError = errors.first;
        final message = firstError is Map<String, dynamic>
            ? firstError['message']?.toString()
            : firstError.toString();
        throw Exception('GraphQL ошибка: $message');
      }

      final statsPayload = data['data'];
      if (statsPayload is! Map<String, dynamic>) {
        throw Exception('Данные GraphQL отсутствуют');
      }

      return MainClientStatsModel.fromJson(statsPayload);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('GraphQL: таймаут соединения');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('GraphQL: таймаут получения данных');
      } else {
        throw Exception('GraphQL: ${e.message}');
      }
    }
  }
}

import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/blacklist/blacklist_remote_data_sources.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_response_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/get_clients_query.dart';

class BlacklistRemoteDataSourcesImpl implements BlacklistRemoteDataSources {
  final Dio dio;
  BlacklistRemoteDataSourcesImpl(this.dio);

  @override
  Future<ClientsResponseModel> getClientsBlacklist(
    GetClientsQuery query,
  ) async {
    try {
      final response = await dio.get(
        '/api/Client/blacklist',
        queryParameters: query.toQueryParams(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return ClientsResponseModel.fromJson(data);
      } else {
        throw Exception(
          'Неожиданный формат данных: ожидается объект с пагинацией',
        );
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения клиентов: ${e.message}');
    }
  }

  @override
  Future<void> fromBlackList(int id) async {
    try {
      await dio.put('/api/Client/$id/from_blacklist');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Недостваточно прав');
      }
      throw Exception(
        'Ошибка удаления клиента из черного списка: ${e.message}',
      );
    }
  }

  @override
  Future<void> toBlackList(int id) async {
    try {
      await dio.put('/api/Client/$id/to_blacklist');
    } on DioException catch (e) {
      throw Exception(
        'Ошибка добавления клиента в черный список: ${e.message}',
      );
    }
  }
}

import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
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
        'Client/blacklist',
        queryParameters: query.toQueryParams(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return ClientsResponseModel.fromJson(data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить клиентов.');
    }
  }

  @override
  Future<void> fromBlackList(int id) async {
    try {
      await dio.put('Client/$id/from_blacklist');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const ApiError('Недостаточно прав.');
      }
      throw mapApiError(
        e,
        fallback: 'Не удалось убрать клиента из чёрного списка.',
      );
    }
  }

  @override
  Future<void> toBlackList(int id) async {
    try {
      await dio.put('Client/$id/to_blacklist');
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось добавить клиента в чёрный список.',
      );
    }
  }
}

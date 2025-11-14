import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_response_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/create_clients_requests.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/get_clients_query.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/update_client_doc_issue_date_requests.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/update_client_doc_request.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/update_client_request.dart';

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  final Dio dio;

  ClientRemoteDataSourceImpl(this.dio);

  @override
  Future<ClientsResponseModel> getClients(GetClientsQuery query) async {
    try {
      final response = await dio.get(
        '/api/Client',
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
  Future<ClientModel> getClientById(int id) async {
    try {
      final response = await dio.get('/api/Client/$id');

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return ClientModel.fromJson(data);
      } else {
        throw Exception('Неожиданный формат данных: ожидается объект клиента');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка получения клиента по ID: ${e.message}');
    }
  }

  @override
  Future<void> deleteClient(int id) async {
    try {
      await dio.delete('/api/Client/$id');
    } on DioException catch (e) {
      throw Exception('Ошибка удаления клиента: ${e.message}');
    }
  }

  @override
  Future<void> updateClientBasic(int id, UpdateClientRequest request) async {
    try {
      await dio.put('/api/Client/$id', data: request.toJson());
    } on DioException catch (e) {
      throw Exception(
        'Ошибка обновления основных данных клиента: ${e.message}',
      );
    }
  }

  @override
  Future<void> updateClientDoc(int id, UpdateClientDocRequest request) async {
    try {
      await dio.put('/api/Client/$id/doc', data: request.toJson());
    } on DioException catch (e) {
      throw Exception('Ошибка обновления документа клиента: ${e.message}');
    }
  }

  @override
  Future<void> updateClientDocIssueDate(
    int id,
    UpdateClientDocIssueDateRequest request,
  ) async {
    try {
      await dio.put('/api/Client/$id/doc-issue-date', data: request.toJson());
    } on DioException catch (e) {
      throw Exception('Ошибка обновления даты документа клиента: ${e.message}');
    }
  }

  @override
  Future<void> createClient(CreateClientRequest request) async {
    try {
      await dio.post('/api/Client', data: request.toJson());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('409 Клиент с такими данными уже существует');
      }
      throw Exception('Ошибка создания клиента: ${e.message}');
    }
  }
}

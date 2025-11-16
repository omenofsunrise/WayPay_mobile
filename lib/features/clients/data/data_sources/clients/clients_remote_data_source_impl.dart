import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_response_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/create_clients_requests.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/get_clients_query.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/passport_photo_type.dart';
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

  @override
  Future<void> uploadPassportPhoto(
    int id,
    PassportPhotoType type,
    File file,
  ) async {
    try {
      final formData = FormData.fromMap({
        'PhotoType': type.apiValue,
        'File': await MultipartFile.fromFile(file.path),
      });
      await dio.post('/api/Client/$id/passport-photo', data: formData);
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки фото паспорта: ${e.message}');
    }
  }

  @override
  Future<void> deletePassportPhoto(int id, PassportPhotoType type) async {
    try {
      await dio.delete(
        '/api/Client/$id/passport-photo',
        queryParameters: {'photoType': type.apiValue},
      );
    } on DioException catch (e) {
      throw Exception('Ошибка удаления фото паспорта: ${e.message}');
    }
  }

  @override
  Future<Uint8List?> fetchPassportPhoto(int id, PassportPhotoType type) async {
    try {
      final response = await dio.get(
        '/api/Client/$id/passport-photo',
        queryParameters: {'photoType': type.apiValue},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Uint8List) return data;
        if (data is List<int>) return Uint8List.fromList(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Ошибка получения фото паспорта: ${e.message}');
    }
  }
}

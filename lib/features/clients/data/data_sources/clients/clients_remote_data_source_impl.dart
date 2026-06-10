import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
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
        'Client',
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
  Future<ClientModel> getClientById(int id) async {
    try {
      final response = await dio.get('Client/$id');

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return ClientModel.fromJson(data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить клиента.');
    }
  }

  @override
  Future<void> deleteClient(int id) async {
    try {
      await dio.delete('Client/$id');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить клиента.');
    }
  }

  @override
  Future<void> updateClientBasic(int id, UpdateClientRequest request) async {
    try {
      await dio.put('Client/$id', data: request.toJson());
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось обновить данные клиента.',
      );
    }
  }

  @override
  Future<void> updateClientDoc(int id, UpdateClientDocRequest request) async {
    try {
      await dio.put('Client/$id/doc', data: request.toJson());
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось обновить документ клиента.',
      );
    }
  }

  @override
  Future<void> updateClientDocIssueDate(
    int id,
    UpdateClientDocIssueDateRequest request,
  ) async {
    try {
      await dio.put('Client/$id/doc-issue-date', data: request.toJson());
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось обновить дату выдачи документа.',
      );
    }
  }

  @override
  Future<void> createClient(CreateClientRequest request) async {
    try {
      await dio.post('Client', data: request.toJson());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const ApiError('Клиент с такими данными уже существует.');
      }
      throw mapApiError(e, fallback: 'Не удалось создать клиента.');
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
      await dio.post('Client/$id/passport-photo', data: formData);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить фото паспорта.');
    }
  }

  @override
  Future<void> deletePassportPhoto(int id, PassportPhotoType type) async {
    try {
      await dio.delete(
        'Client/$id/passport-photo',
        queryParameters: {'photoType': type.apiValue},
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить фото паспорта.');
    }
  }

  @override
  Future<Uint8List?> fetchPassportPhoto(int id, PassportPhotoType type) async {
    try {
      final response = await dio.get(
        'Client/$id/passport-photo',
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
      throw mapApiError(e, fallback: 'Не удалось загрузить фото паспорта.');
    }
  }
}

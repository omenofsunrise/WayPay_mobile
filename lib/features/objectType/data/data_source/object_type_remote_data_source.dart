import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/objectType/data/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';

abstract class ObjectTypeRemoteDataSource {
  Future<ObjectTypeResponseModel> getObjectTypes(GetObjectTypesQuery query);
  Future<ObjectTypeModel> createObjectType(CreateObjectTypeRequest request);
  Future<ObjectTypeModel> updateObjectType(
    int id,
    UpdateObjectTypeRequest request,
  );
  Future<void> deleteObjectType(int id);
  Future<bool> checkObjectTypeExists(CheckObjectTypeExistsQuery query);
}

class ObjectTypeRemoteDataSourceImpl implements ObjectTypeRemoteDataSource {
  final Dio dio;

  ObjectTypeRemoteDataSourceImpl(this.dio);

  @override
  Future<ObjectTypeResponseModel> getObjectTypes(
    GetObjectTypesQuery query,
  ) async {
    try {
      final response = await dio.get(
        'ObjectType',
        queryParameters: query.toQueryParams(),
      );

      if (response.data is Map<String, dynamic>) {
        return ObjectTypeResponseModel.fromJson(response.data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить типы объектов.');
    }
  }

  @override
  Future<ObjectTypeModel> createObjectType(
    CreateObjectTypeRequest request,
  ) async {
    try {
      final response = await dio.post(
        'ObjectType',
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return ObjectTypeModel.fromJson(response.data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать тип объекта.');
    }
  }

  @override
  Future<ObjectTypeModel> updateObjectType(
    int id,
    UpdateObjectTypeRequest request,
  ) async {
    try {
      final response = await dio.put(
        'ObjectType/$id',
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return ObjectTypeModel.fromJson(response.data);
      } else {
        throw const ApiError('Сервер вернул некорректный ответ.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить тип объекта.');
    }
  }

  @override
  Future<void> deleteObjectType(int id) async {
    try {
      final response = await dio.delete('ObjectType/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ApiError('Не удалось удалить тип объекта.');
      }
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить тип объекта.');
    }
  }

  @override
  Future<bool> checkObjectTypeExists(CheckObjectTypeExistsQuery query) async {
    try {
      final response = await dio.get(
        'ObjectType/exists',
        queryParameters: query.toQueryParams(),
      );

      return response.data as bool;
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось проверить наличие типа объекта.',
      );
    }
  }
}

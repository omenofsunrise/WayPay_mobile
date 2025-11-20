import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/product/data/data_sources/products_remote_data_source.dart';
import 'package:waypay_mobile/features/product/data/models/products_response_model.dart';

import 'package:waypay_mobile/features/product/data/models/product_model.dart';

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final Dio dio;

  ProductsRemoteDataSourceImpl(this.dio);

  @override
  Future<ProductsResponseModel> getProducts({
    int? page,
    int? pageSize,
    String? sortDirection,
    String? sortBy,
    String? name,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (sortDirection != null && sortDirection.isNotEmpty) {
        queryParams['sortDirection'] = sortDirection;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }
      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final response = await dio.get(
        'Product',
        queryParameters: queryParams,
      );

      return ProductsResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Ошибка при загрузке продуктов: ${e.response?.data}');
    }
  }

  @override
  Future<void> createProduct({required String name}) async {
    try {
      final payload = {"name": name};

      final response = await dio.post('Product', data: payload);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка создания продукта: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при создании продукта: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await dio.get('Product/$id');

      return ProductModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при загрузке продукта: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<void> updateProduct({required int id, required String name}) async {
    try {
      final payload = {"name": name};

      final response = await dio.put('Product/$id', data: payload);

      if (response.statusCode != 200) {
        throw Exception('Ошибка обновления продукта: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при обновлении продукта: ${e.response?.data ?? e.message}',
      );
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      final response = await dio.delete('Product/$id');

      if (response.statusCode != 200) {
        throw Exception('Ошибка удаления продукта: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при удалении продукта: ${e.response?.data ?? e.message}',
      );
    }
  }
}

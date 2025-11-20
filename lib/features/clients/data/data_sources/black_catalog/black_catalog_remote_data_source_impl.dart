import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/black_catalog/black_catalog_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/black_catalog/get_black_catalog_query.dart';
import 'package:waypay_mobile/features/clients/data/models/black_catalog/paged_black_catalog_result.dart';

class BlackCatalogRemoteDataSourceImpl
    implements BlackCatalogRemoteDataSource {
  BlackCatalogRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PagedBlackCatalogResult> getBlackCatalog(
    GetBlackCatalogQuery query,
  ) async {
    try {
      final response = await _dio.get(
        'BlackList',
        queryParameters: query.toQueryParams(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PagedBlackCatalogResult.fromJson(data);
      }
      throw Exception('Неожиданный формат данных чёрного каталога');
    } on DioException catch (e) {
      throw Exception('Ошибка загрузки чёрного каталога: ${e.message}');
    }
  }
}

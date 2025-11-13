import 'package:dio/dio.dart';
import 'package:waypay/features/sold_products/data/data_sources/sold_product_remote_data_source.dart';
import 'package:waypay/features/sold_products/data/models/sold_product_model.dart';

class SoldProductRemoteDataSourceImpl implements SoldProductRemoteDataSource {
  final Dio dio;

  SoldProductRemoteDataSourceImpl(this.dio);

  @override
  Future<List<SoldProductModel>> fetchSoldProductsByCreditId(
    int creditId,
  ) async {
    final response = await dio.get('/api/SoldProduct/by-credit/$creditId');

    if (response.statusCode == 200) {
      final data = response.data as List;
      return data.map((e) => SoldProductModel.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка при загрузке проданных товаров');
    }
  }
}

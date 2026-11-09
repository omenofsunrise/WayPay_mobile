import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/clients/data/models/blacklist_plus_model.dart';

class BlacklistPlusRemoteDataSource {
  const BlacklistPlusRemoteDataSource(this.dio);

  final Dio dio;

  Future<BlacklistPlusSearchResult> search({
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await dio.get(
        'BlackList',
        queryParameters: {
          if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'page': 1,
          'pageSize': 100,
        },
      );
      return BlacklistPlusSearchResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось выполнить проверку в ЧС+.');
    }
  }
}

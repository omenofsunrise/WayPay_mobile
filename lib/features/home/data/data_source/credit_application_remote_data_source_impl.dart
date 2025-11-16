import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/home/data/data_source/credit_application_remote_data_source.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_model.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_paged_result.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/create_credit_application_request.dart';
import 'package:waypay_mobile/features/home/data/models/credit_applications/get_credit_applications_query.dart';

class CreditApplicationRemoteDataSourceImpl
    implements CreditApplicationRemoteDataSource {
  CreditApplicationRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<CreditApplicationPagedResult> getCreditApplications(
    GetCreditApplicationsQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/api/CreditApplication',
        queryParameters: query.toQueryParams(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return CreditApplicationPagedResult.fromJson(data);
      }

      throw Exception('Неожиданный формат ответа при загрузке заявок');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ??
              e.response?.data['error']?.toString())
          : e.message;
      throw Exception('Ошибка при загрузке заявок: $message');
    }
  }

  @override
  Future<CreditApplicationModel> createCreditApplication(
    CreateCreditApplicationRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/CreditApplication',
        data: request.toJson(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return CreditApplicationModel.fromJson(data);
      }

      throw Exception('Неожиданный формат ответа при создании заявки');
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ??
              e.response?.data['error']?.toString())
          : e.message;
      throw Exception('Ошибка при создании заявки: $message');
    }
  }
}

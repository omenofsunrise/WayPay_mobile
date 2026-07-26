import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
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
        'CreditApplication',
        queryParameters: query.toQueryParams(),
      );

      final data = response.data;

      // Обычный ответ — объект с пагинацией {items, page, ...}
      if (data is Map) {
        return CreditApplicationPagedResult.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      // Сервер может вернуть голый массив заявок без обёртки пагинации
      if (data is List) {
        return CreditApplicationPagedResult.fromJson({'items': data});
      }

      throw ApiError(
        'Сервер вернул некорректный ответ (тип: ${data.runtimeType}).',
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить заявки.');
    }
  }

  @override
  Future<CreditApplicationModel> createCreditApplication(
    CreateCreditApplicationRequest request,
  ) async {
    try {
      final response = await _dio.post(
        'CreditApplication',
        data: request.toJson(),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        return CreditApplicationModel.fromJson(data);
      }

      throw const ApiError('Сервер вернул некорректный ответ.');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось создать заявку.');
    }
  }
}

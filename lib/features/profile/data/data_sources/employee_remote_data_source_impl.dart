import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/features/profile/data/data_sources/employee_remote_data_source.dart';
import 'package:waypay_mobile/features/profile/data/models/credit_stat.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/profile/data/models/payment_stat.dart';

class EmployeeRemoteDataSourceImpl implements EmployeeRemoteDataSource {
  final Dio dio;

  EmployeeRemoteDataSourceImpl(this.dio);

  @override
  Future<void> uploadEmployeePhoto({
    required int id,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      final mimeParts = mimeType.split('/');
      final formData = FormData.fromMap({
        'Id': id.toString(),
        'Photo': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ),
      });

      await dio.put('Employee/photo', data: formData);
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось загрузить фото.');
    }
  }

  @override
  Future<void> updateEmployeeProfile({
    required int id,
    required String fullName,
    required String address,
  }) async {
    try {
      final formData = FormData.fromMap({
        'Id': id.toString(),
        'FullName': fullName,
        'Address': address,
      });

      await dio.put(
        'Employee',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось обновить профиль сотрудника.');
    }
  }

  @override
  Future<void> deleteEmployeePhoto() async {
    try {
      await dio.delete('Employee/photo');
    } on DioException catch (e) {
      throw mapApiError(e, fallback: 'Не удалось удалить фото.');
    }
  }

  @override
  Future<EmployeesResponse> fetchEmployees({
    int? page,
    int? pageSize,
    String? fullName,
    String? role,
    String? sortBy,
    String? sortDirection,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (fullName != null) queryParams['fullName'] = fullName;
    if (role != null) queryParams['role'] = role;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortDirection != null) queryParams['sortDirection'] = sortDirection;

    final response = await dio.get('Employee', queryParameters: queryParams);

    debugPrint('Ответ от API /api/Employee: ${response.data}');

    if (response.statusCode == 200) {
      return EmployeesResponse.fromJson(response.data);
    } else {
      throw const ApiError('Не удалось загрузить сотрудников.');
    }
  }

  @override
  Future<void> updateEmployeeRole(int id, String newRole) async {
    try {
      final response = await dio.patch(
        'Employee/role/$id',
        data: '"$newRole"',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint(
        'Ответ от PATCH /api/Employee/role/$id: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw const ApiError('Не удалось обновить роль сотрудника.');
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw mapApiError(e, fallback: 'Не удалось обновить роль сотрудника.');
    }
  }

  @override
  Future<void> updateEmployeePhone(int id, String phone) async {
    final response = await dio.patch(
      'Employee/phone/$id',
      data: '"$phone"',
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    if (response.statusCode != 200) {
      throw const ApiError('Не удалось обновить телефон.');
    }
  }

  @override
  Future<void> updateEmployeeMinSurcharge(int id, int minSurcharge) async {
    final response = await dio.patch(
      'Employee/min-surcharge/$id',
      data: minSurcharge,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    if (response.statusCode != 200) {
      throw const ApiError('Не удалось обновить надбавку.');
    }
  }

  @override
  Future<void> createEmployee({
    required String fullName,
    required String phone,
    required String address,
    required int minSurcharge,
    required String role,
  }) async {
    debugPrint('=== Создание сотрудника ===');
    debugPrint('FullName: $fullName');
    debugPrint('Phone: $phone');
    debugPrint('Address: $address');
    debugPrint('MinSurcharge: $minSurcharge');
    debugPrint('Role: $role');
    debugPrint('===========================');

    final formData = FormData.fromMap({
      'FullName': fullName,
      'Phone': phone,
      'Address': address,
      'MinSurcharge': minSurcharge,
      'Role': role,
    });

    try {
      final response = await dio.post(
        'Employee',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      debugPrint('Ответ от POST /api/Employee: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw const ApiError('Не удалось создать сотрудника.');
      }
    } catch (e) {
      debugPrint('Ошибка при создании сотрудника: $e');
      if (e is ApiError) rethrow;
      throw mapApiError(e, fallback: 'Не удалось создать сотрудника.');
    }
  }

  @override
  Future<Map<String, dynamic>> getEmployeeById(int id) async {
    final response = await dio.get('Employee/$id');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw const ApiError('Не удалось загрузить пользователя.');
    }
  }

  @override
  @override
  Future<void> deleteEmployee(int id) async {
    final response = await dio.delete('Employee/$id');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      throw const ApiError('Не удалось удалить сотрудника.');
    }
  }

  @override
  Future<List<CreditStat>> getCreditsStats({int months = 12}) async {
    final response = await dio.get(
      'Employee/credits-stats',
      queryParameters: {'months': months},
    );

    if (response.statusCode == 200) {
      final List list = response.data;
      return list.map((e) => CreditStat.fromJson(e)).toList();
    } else {
      throw const ApiError('Не удалось загрузить статистику по договорам.');
    }
  }

  @override
  Future<List<PaymentStat>> getPaymentsStats({int months = 12}) async {
    final response = await dio.get(
      'Employee/payments-stats',
      queryParameters: {'months': months},
    );
    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List)
          .map((e) => PaymentStat.fromJson(e))
          .toList();
    } else {
      throw const ApiError('Не удалось загрузить статистику по платежам.');
    }
  }

  @override
  Future<List<PaymentStat>> getPaymentsStatsById({
    required int employeeId,
    int months = 12,
  }) async {
    final url = 'Employee/payments-stats$employeeId';
    debugPrint('📡 [Request] GET $url?months=$months');

    final response = await dio.get(url, queryParameters: {'months': months});

    debugPrint('✅ [Response ${response.statusCode}] $url');

    if (response.statusCode == 200) {
      final List data = response.data;
      debugPrint('📦 [Data] Loaded ${data.length} records');
      return data.map((e) => PaymentStat.fromJson(e)).toList();
    } else {
      throw const ApiError('Не удалось загрузить статистику по платежам.');
    }
  }

  @override
  Future<List<CreditStat>> getCreditsStatsById({
    required int employeeId,
    int months = 12,
  }) async {
    try {
      final url = 'Employee/credits-stats$employeeId';
      final query = {'months': months};

      debugPrint('📡 [Request] GET $url?months=$months');

      final response = await dio.get(url, queryParameters: query);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        debugPrint('✅ [Response] ${data.length} items loaded');

        return data.map((e) => CreditStat.fromJson(e)).toList();
      } else {
        debugPrint('❌ [Error] Status code: ${response.statusCode}');
        throw const ApiError('Не удалось загрузить статистику по договорам.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Exception] $e');
      debugPrint('$stackTrace');
      if (e is ApiError) rethrow;
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить статистику по договорам.',
      );
    }
  }

  @override
  Future<List<EmployeeName>> getEmployeeFullNames() async {
    try {
      final response = await dio.get('Employee/fullnames');

      debugPrint('📡 [Request] GET /api/Employee/fullnames');
      debugPrint('✅ [Response ${response.statusCode}] ${response.data}');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => EmployeeName.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw const ApiError('Не удалось загрузить список сотрудников.');
      }
    } on DioException catch (e) {
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить список сотрудников.',
      );
    }
  }
}

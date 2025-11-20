import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:waypay_mobile/features/admin_panel/data/data_sources/company_remote_data_source.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/company_model.dart';
import 'package:waypay_mobile/features/admin_panel/data/models/post_company_model.dart';
import 'package:waypay_mobile/features/info/data/models/common_info.dart';

class CompanyRemoteDataSourceImpl implements CompanyRemoteDataSource {
  final Dio dio;

  CompanyRemoteDataSourceImpl(this.dio);

  @override
  Future<List<CompanyModel>> getCompanies() async {
    try {
      final response = await dio.get('Company/all');
      final data = response.data as List;

      return data.map((json) => CompanyModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Ошибка при загрузке компаний: ${e.message}');
    }
  }

  @override
  Future<CompanyModel> getSingleCompany() async {
    try {
      final response = await dio.get('Company');
      final data = response.data as Map<String, dynamic>;
      return CompanyModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception('Ошибка при загрузке компании: ${e.message}');
    }
  }

  @override
  Future<void> createCompany(CompanyCreateRequest request) async {
    try {
      await dio.post('Company', data: request.toJson());
    } on DioException catch (e) {
      throw Exception('Ошибка при создании компании: ${e.message}');
    }
  }

  @override
  Future<void> updateCompanyLicenceDate(int id, DateTime newDate) async {
    try {
      await dio.patch(
        'Company/licence-date/$id',
        data: '"${newDate.toUtc().toIso8601String()}"',
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      throw Exception('Ошибка при обновлении даты лицензии: ${e.message}');
    }
  }

  @override
  Future<void> updateCompanyPhone(int id, String newPhone) async {
    try {
      await dio.patch(
        'Company/phone/$id',
        data: '"$newPhone"',
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (e) {
      throw Exception('Ошибка при обновлении телефона: ${e.message}');
    }
  }

  @override
  Future<void> deleteCompany(int id) async {
    try {
      final response = await dio.delete('Company/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Ошибка при удалении компании');
      }
    } on DioException catch (e) {
      throw Exception('Ошибка при удалении компании: ${e.message}');
    }
  }

  @override
  Future<void> uploadCompanyPhoto({required String filePath}) async {
    try {
      final fileName = filePath.split('/').last;
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      final mimeParts = mimeType.split('/');

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ),
      });

      await dio.patch('Company/photo', data: formData);
    } on DioException catch (e) {
      throw Exception('Ошибка при загрузке логотипа: ${e.message}');
    }
  }

  @override
  Future<void> updateCompany(CompanyModel company) async {
    try {
      final data = company.toUpdateJson();
      await dio.put('Company', data: data);
    } on DioException catch (e) {
      throw Exception('Ошибка при обновлении данных компании: ${e.message}');
    }
  }

  @override
  Future<CompanyCommonInfo> getCompanyCommonInfo() async {
    try {
      final response = await dio.get(
        'Company/common-info',
        options: Options(headers: {'accept': 'text/plain'}),
      );
      final data = response.data;

      return CompanyCommonInfo.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        'Ошибка при загрузке общей информации компании: ${e.message}',
      );
    }
  }
}

import 'package:dio/dio.dart';
import 'package:waypay_mobile/features/home/data/data_source/home_remote_data_source.dart';
import 'package:waypay_mobile/features/home/data/models/employee_model.dart';

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSourceImpl(this.dio);

  @override
  Future<EmployeeModel> getEmployeeData() async {
    try {
      final response = await dio.get('/employee');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return EmployeeModel.fromJson(response.data);
        } else {
          throw Exception('Неожиданный формат ответа: ожидался JSON объект');
        }
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Ошибка авторизации');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Данные сотрудника не найдены');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Таймаут соединения');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Таймаут получения данных');
      } else {
        throw Exception('Ошибка загрузки данных сотрудника: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }
}

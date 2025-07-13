import 'package:dio/dio.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay/features/auth/data/models/call_confirm_request_model.dart';
import 'package:waypay/features/auth/data/models/refresh_token_request_model.dart';
import 'package:waypay/features/auth/data/models/refresh_token_response_model.dart';
import 'package:waypay/features/auth/data/models/start_auth_request_model.dart';
import 'package:waypay/features/auth/data/models/start_auth_response_model.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<StartAuthResponseModel> startAuth(
    StartAuthRequestModel request,
  ) async {
    try {
      final response = await dio.post(
        '/api/Auth/start',
        data: request.toJson(),
      );

      return StartAuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Ошибка старта авторизации: ${e.message}');
    }
  }

  @override
  Future<void> confirmCall(CallConfirmRequestModel request) async {
    try {
      final response = await dio.post(
        '/api/Auth/confirm',
        data: request.toJson(),
      );

      print('🔐 Ответ confirmCall: ${response.data}');

      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('accessToken') &&
            data.containsKey('refreshToken')) {
          final tokenStorage = TokenStorage();
          await tokenStorage.saveTokens(
            accessToken: data['accessToken'] as String,
            refreshToken: data['refreshToken'] as String,
          );
          await tokenStorage.setAuthenticated(true);

          print('✅ Токены сохранены после confirmCall');
        } else {
          print('⚠️ Токены не найдены в ответе confirmCall');
        }
      }
    } on DioException catch (e) {
      throw Exception('Ошибка подтверждения звонка: ${e.message}');
    }
  }

  @override
  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  ) async {
    try {
      final response = await dio.post(
        '/api/Auth/refresh',
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer ${request.accessToken}'},
        ),
      );

      final tokenStorage = TokenStorage();
      await tokenStorage.saveTokens(
        accessToken: response.data['accessToken'] as String,
        refreshToken: request.refreshToken,
      );

      return RefreshTokenResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Ошибка обновления токена: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>> getAuthInfo() async {
    try {
      final response = await dio.get('/api/Auth/info');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        'Ошибка получения информации о пользователе: ${e.message}',
      );
    }
  }

  @override
  Future<void> revokeSession(int tokenId) async {
    try {
      await dio.post('/api/Auth/revoke-session/$tokenId');
    } on DioException catch (e) {
      throw Exception('Ошибка при отзыве сессии: ${e.message}');
    }
  }
}

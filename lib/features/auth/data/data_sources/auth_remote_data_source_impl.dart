import 'package:dio/dio.dart';
import 'package:waypay_mobile/core/network/api_error.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:waypay_mobile/features/auth/data/models/call_confirm_request_model.dart';
import 'package:waypay_mobile/features/auth/data/models/refresh_token_request_model.dart';
import 'package:waypay_mobile/features/auth/data/models/refresh_token_response_model.dart';
import 'package:waypay_mobile/features/auth/data/models/session_model.dart';
import 'package:waypay_mobile/features/auth/data/models/start_auth_request_model.dart';
import 'package:waypay_mobile/features/auth/data/models/start_auth_response_model.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<StartAuthResponseModel> startAuth(
    StartAuthRequestModel request,
  ) async {
    try {
      print('➡️ Старт авторизации: ${request.toJson()}');
      final response = await dio.post(
        'Auth/start',
        data: request.toJson(),
      );
      print('✅ Успешный ответ startAuth: ${response.data}');
      return StartAuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Ошибка startAuth: ${e.response?.data}');
      throw mapApiError(
        e,
        fallback: 'Не удалось начать авторизацию. Попробуйте ещё раз.',
      );
    }
  }

  @override
  Future<void> confirmCall(CallConfirmRequestModel request) async {
    try {
      print('➡️ Подтверждение звонка: ${request.toJson()}');
      final response = await dio.post(
        'Auth/confirm',
        data: request.toJson(),
      );

      print('✅ Ответ confirmCall: ${response.data}');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('accessToken') &&
            data.containsKey('refreshToken')) {
          final tokenStorage = TokenStorage();
          await tokenStorage.saveTokens(
            accessToken: data['accessToken'] as String,
            refreshToken: data['refreshToken'] as String,
          );
          await tokenStorage.setAuthenticated(true);

          print('🔐 Токены сохранены после confirmCall');
        } else {
          print('⚠️ Токены не найдены в ответе confirmCall');
        }
      }
    } on DioException catch (e) {
      print('❌ Ошибка confirmCall: ${e.response?.data}');
      throw mapApiError(
        e,
        fallback: 'Не удалось подтвердить звонок. Попробуйте ещё раз.',
      );
    }
  }

  @override
  Future<RefreshTokenResponseModel> refreshToken(
    RefreshTokenRequestModel request,
  ) async {
    try {
      final tokenStorage = TokenStorage();
      final savedPin = await tokenStorage.getPinCode();

      final body = {
        'accessToken': request.accessToken,
        'refreshToken': request.refreshToken,
      };

      if (savedPin != null) {
        body['pinCode'] = savedPin;
      }

      print('🔄 Запрос на обновление токена: $body');

      final response = await dio.post(
        'Auth/refresh',
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer ${request.accessToken}'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken =
          data['refreshToken'] as String? ?? request.refreshToken;

      await tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      print(
        '✅ Токены обновлены: accessToken=${newAccessToken.substring(0, 10)}...',
      );

      return RefreshTokenResponseModel.fromJson(data);
    } on DioException catch (e) {
      print('❌ Ошибка refreshToken: ${e.response?.data}');
      throw mapApiError(
        e,
        fallback: 'Не удалось обновить сессию. Войдите заново.',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getAuthInfo() async {
    try {
      print('📥 Получение информации о пользователе...');
      final response = await dio.get('Auth/info');
      print('✅ Информация получена: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('❌ Ошибка getAuthInfo: ${e.response?.data}');
      throw mapApiError(
        e,
        fallback: 'Не удалось получить данные пользователя.',
      );
    }
  }

  @override
  Future<void> setupPin(String pinCode) async {
    try {
      final tokenStorage = TokenStorage();
      final accessToken = await tokenStorage.getAccessToken();

      print('📌 Установка PIN: $pinCode');
      print('🛡️ AccessToken: ${accessToken?.substring(0, 10)}...');

      final response = await dio.post(
        'Auth/setup-pin',
        data: {'pinCode': pinCode},
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Ответ setup-pin: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;

          if (data.containsKey('accessToken') &&
              data.containsKey('refreshToken')) {
            await tokenStorage.saveTokens(
              accessToken: data['accessToken'] as String,
              refreshToken: data['refreshToken'] as String,
            );
            await tokenStorage.setAuthenticated(true);
            print('✅ Токены сохранены после setupPin');
          }
        }
        return;
      }

      throw ApiError(
        'Не удалось сохранить PIN. Попробуйте ещё раз.',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      print('❌ Ошибка setupPin: ${e.response?.data}');
      throw mapApiError(
        e,
        fallback: 'Не удалось сохранить PIN. Попробуйте ещё раз.',
      );
    }
  }

  @override
  Future<List<SessionModel>> getSessions() async {
    try {
      print('📥 Получение списка сессий...');
      final tokenStorage = TokenStorage();
      final access = await tokenStorage.getAccessToken();

      final response = await dio.get(
        'Auth/sessions',
        options: access != null
            ? Options(headers: {'Authorization': 'Bearer $access'})
            : null,
      );

      final data = response.data;
      if (data is List) {
        final result = data
            .map(
              (e) => SessionModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        print('✅ Сессий: ${result.length}');
        return result;
      }

      throw const ApiError('Не удалось загрузить список сессий.');
    } on DioException catch (e) {
      print('❌ Ошибка getSessions: ${e.response?.data}');
      throw mapApiError(
        e,
        fallback: 'Не удалось загрузить список сессий.',
      );
    }
  }

  @override
  Future<void> revokeSession(int tokenId) async {
    final tokenStorage = TokenStorage();
    final access = await tokenStorage.getAccessToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (access != null) 'Authorization': 'Bearer $access',
    };

    Future<Response<dynamic>> post(dynamic body) {
      return dio.post(
        'Auth/revoke-session',
        data: body,
        options: Options(headers: headers),
      );
    }

    try {
      final res = await post(tokenId);
      if (res.statusCode == 200) return;

      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Unexpected status: ${res.statusCode}',
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;

      if (code == 400 || code == 415) {
        try {
          final r1 = await post({'sessionId': tokenId});
          if (r1.statusCode == 200) return;

          final r2 = await post({'tokenId': tokenId});
          if (r2.statusCode == 200) return;
        } catch (_) {}
      }

      if (code == 404) {
        throw const ApiError('Сессия уже завершена или не найдена.');
      }

      throw mapApiError(
        e,
        fallback: 'Не удалось завершить сессию. Попробуйте ещё раз.',
      );
    }
  }
}

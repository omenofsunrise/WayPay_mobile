import 'package:dio/dio.dart';
import 'token_storage.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://web.waypay.one:5001',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final tokenStorage = TokenStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshToken = await tokenStorage.getRefreshToken();
          final accessToken = await tokenStorage.getAccessToken();

          if (refreshToken != null && accessToken != null) {
            try {
              final refreshResponse = await dio.post(
                '/api/Auth/refresh',
                data: {
                  'accessToken': accessToken,
                  'refreshToken': refreshToken,
                },
                options: Options(
                  headers: {'Authorization': 'Bearer $accessToken'},
                ),
              );

              final newAccessToken =
                  refreshResponse.data['accessToken'] as String;
              await tokenStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: refreshToken,
              );

              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';

              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (refreshError) {
              await tokenStorage.clearAll();
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}

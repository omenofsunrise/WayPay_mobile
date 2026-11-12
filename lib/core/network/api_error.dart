import 'package:dio/dio.dart';

/// Унифицированная ошибка API, которую можно безопасно показать пользователю.
/// Поле [message] всегда содержит текст на русском языке без технических деталей.
class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? data;

  const ApiError(this.message, {this.statusCode, this.code, this.data});

  @override
  String toString() => message;
}

const String _genericMessage = 'Что-то пошло не так. Попробуйте ещё раз.';

/// Преобразует любую ошибку в [ApiError] с понятным пользователю текстом.
/// [fallback] используется, если из ошибки не удалось вытащить осмысленный
/// серверный текст и нет подходящего стандартного сообщения.
ApiError mapApiError(Object error, {String? fallback}) {
  if (error is ApiError) return error;
  if (error is DioException) return _fromDio(error, fallback: fallback);

  final raw = error.toString();
  final cleaned = raw.startsWith('Exception:')
      ? raw.replaceFirst('Exception:', '').trim()
      : raw.trim();
  return ApiError(cleaned.isNotEmpty ? cleaned : (fallback ?? _genericMessage));
}

ApiError _fromDio(DioException e, {String? fallback}) {
  final status = e.response?.statusCode;
  final data = e.response?.data;

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return ApiError(
        'Превышено время ожидания. Возможно, у вас включён VPN — '
        'отключите его и попробуйте ещё раз. Также проверьте интернет-соединение.',
        statusCode: status,
        code: 'TIMEOUT',
      );
    case DioExceptionType.connectionError:
      return ApiError(
        'Нет подключения к интернету. Проверьте сеть и попробуйте снова.',
        statusCode: status,
      );
    case DioExceptionType.cancel:
      return ApiError('Запрос был отменён.', statusCode: status);
    case DioExceptionType.badCertificate:
      return ApiError(
        'Не удалось проверить безопасное соединение. Попробуйте позже.',
        statusCode: status,
      );
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  final serverMessage = _extractServerMessage(data);
  final serverCode = _extractServerCode(data);

  final byBusinessCode = _mapBusinessSignal(serverCode, data, status);
  if (byBusinessCode != null) return byBusinessCode;

  switch (status) {
    case 400:
      return ApiError(
        serverMessage ??
            'Запрос содержит ошибку. Проверьте введённые данные и попробуйте снова.',
        statusCode: status,
        code: serverCode,
        data: _asMap(data),
      );
    case 401:
      return ApiError(
        'Сессия истекла. Войдите заново.',
        statusCode: status,
        code: serverCode,
      );
    case 403:
      return ApiError(
        'Недостаточно прав для выполнения операции.',
        statusCode: status,
        code: serverCode,
      );
    case 404:
      return ApiError(
        'Данные не найдены.',
        statusCode: status,
        code: serverCode,
      );
    case 409:
      return ApiError(
        serverMessage ??
            'Конфликт данных: они уже изменились. Обновите страницу и попробуйте снова.',
        statusCode: status,
        code: serverCode,
      );
    case 413:
      return ApiError(
        'Файл слишком большой. Уменьшите размер и повторите.',
        statusCode: status,
      );
    case 415:
      return ApiError('Неподдерживаемый формат данных.', statusCode: status);
    case 422:
      return ApiError(
        serverMessage ??
            'Не удалось обработать запрос. Проверьте заполненные поля.',
        statusCode: status,
      );
    case 429:
      return ApiError(
        'Слишком много запросов. Подождите немного и попробуйте снова.',
        statusCode: status,
      );
    case 500:
    case 502:
    case 503:
    case 504:
      return ApiError(
        'Сервер временно недоступен. Попробуйте позже.',
        statusCode: status,
      );
  }

  if (serverMessage != null && serverMessage.isNotEmpty) {
    return ApiError(serverMessage, statusCode: status, code: serverCode);
  }
  return ApiError(fallback ?? _genericMessage, statusCode: status);
}

ApiError? _mapBusinessSignal(String? code, dynamic data, int? status) {
  switch (code) {
    case 'ACCESS_TOKEN_EXPIRED':
      return ApiError(
        'Сессия истекла. Войдите заново.',
        statusCode: status,
        code: code,
      );
    case 'REFRESH_TOKEN_INVALID':
      return ApiError(
        'Токен недействителен. Войдите заново.',
        statusCode: status,
        code: code,
      );
    case 'REFRESH_TOKEN_EXPIRED':
      return ApiError(
        'Срок действия сессии истёк. Войдите заново.',
        statusCode: status,
        code: code,
      );
    case 'PIN_REQUIRED':
      return ApiError('Нужно ввести PIN-код.', statusCode: status, code: code);
  }

  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final errorText = (map['Error'] ?? map['error'])?.toString() ?? '';

    if (errorText.contains('PIN code is temporarily locked')) {
      final minutesLeft = map['MinutesLeft'] ?? map['minutesLeft'];
      return ApiError(
        minutesLeft != null
            ? 'PIN-код временно заблокирован. Попробуйте через $minutesLeft мин.'
            : 'PIN-код временно заблокирован. Попробуйте позже.',
        statusCode: status,
      );
    }
    if (map['PinInvalid'] == true || map['pinInvalid'] == true) {
      final attemptsLeft = map['AttemptsLeft'] ?? map['attemptsLeft'];
      return ApiError(
        attemptsLeft != null
            ? 'Неверный PIN-код. Осталось попыток: $attemptsLeft.'
            : 'Неверный PIN-код.',
        statusCode: status,
      );
    }
    if (errorText.contains('Refresh token does not belong to this user')) {
      return ApiError(
        'Сессия привязана к другому пользователю. Войдите заново.',
        statusCode: status,
      );
    }
  }
  return null;
}

String? _extractServerMessage(dynamic data) {
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final candidates = [
      map['message'],
      map['Message'],
      map['error'],
      map['Error'],
      map['detail'],
      map['Detail'],
      map['title'],
      map['Title'],
    ];
    for (final v in candidates) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
  }
  if (data is String && data.trim().isNotEmpty) return data.trim();
  return null;
}

String? _extractServerCode(dynamic data) {
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    for (final key in ['errorCode', 'ErrorCode', 'code', 'Code']) {
      final v = map[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
  }
  return null;
}

Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

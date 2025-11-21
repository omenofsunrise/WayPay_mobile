import 'package:flutter/foundation.dart';

class ErrorUtils {
  static String friendlyMessage(
    Object? error, {
    String fallback = 'Не удалось загрузить данные. Попробуйте позже.',
  }) {
    final raw = error?.toString().trim() ?? '';
    if (raw.isEmpty) return fallback;

    final normalized = raw.toLowerCase();

    bool hasAny(List<String> tokens) {
      for (final token in tokens) {
        if (normalized.contains(token)) return true;
      }
      return false;
    }

    if (hasAny(['сессия', 'session', 'unauthorized', '401'])) {
      return 'Сессия истекла. Пожалуйста, войдите снова.';
    }

    if (hasAny([
      'connecttimeout',
      'connection timeout',
      'timeout',
      'socketexception',
      'network is unreachable',
      'failed host lookup',
      'network unreachable',
      'internet connection',
    ])) {
      return 'Нет соединения. Проверьте интернет и попробуйте ещё раз.';
    }

    if (hasAny(['forbidden', 'запрещено', '403'])) {
      return 'Недостаточно прав для выполнения действия.';
    }

    if (hasAny(['500', '502', '503', 'server error', 'internal server'])) {
      return 'Сервис временно недоступен. Попробуйте повторить позже.';
    }

    if (kDebugMode) {
      // Helps to keep original message in logs during debug sessions.
      debugPrint('Raw error: $raw');
    }

    return fallback;
  }
}

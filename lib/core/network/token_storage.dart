import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _accessExpiryKey = 'access_token_expiry';
  static const _isAuthenticatedKey = 'is_authenticated';
  static const _pinCodeKey = 'pin_code';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setString(
      _accessExpiryKey,
      now.add(const Duration(minutes: 5)).toIso8601String(),
    );

    print(
      '✅ Токены сохранены:\nAccessToken: $accessToken\nRefreshToken: $refreshToken',
    );
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_accessExpiryKey);
    final access = prefs.getString(_accessKey);

    if (access == null || expiryStr == null) {
      print('⚠️ Access token или срок действия отсутствуют.');
      return null;
    }

    final expiry = DateTime.tryParse(expiryStr);
    final now = DateTime.now();

    if (expiry != null && now.isAfter(expiry)) {
      print('🔁 Access token истёк, обновляем...');
      return await _refreshAccessToken();
    }

    print('✅ Access token получен из кэша.');
    return access;
  }

  Future<String?> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_refreshKey);
    final access = prefs.getString(_accessKey);
    final pin = prefs.getString(_pinCodeKey);

    if (refresh == null || access == null) {
      print('❌ Нет refresh или access токена.');
      return null;
    }

    print('🔄 Отправка запроса на обновление токена...');
    print('📤 AccessToken: ${access.substring(0, 15)}...');
    print('📤 RefreshToken: ${refresh.substring(0, 10)}...');
    if (pin != null) {
      print('📌 PIN присутствует: ${'*' * pin.length}');
    } else {
      print('⚠️ PIN отсутствует');
    }

    final body = {
      'accessToken': access,
      'refreshToken': refresh,
      if (pin != null) 'pinCode': pin,
    };

    try {
      final response = await http.post(
        Uri.parse('http://test.waypay.one:5000/api/Auth/refresh'),
        headers: {'Content-Type': 'application/json', 'X-Environment': 'dev'},
        body: jsonEncode(body),
      );

      print('📩 Ответ получен: статус ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String? ?? refresh;

        if (newAccess != null) {
          await saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          print('✅ Токены обновлены успешно.');
          return newAccess;
        } else {
          print('❌ Не удалось получить новый accessToken из ответа.');
          print('📩 Ответ: $data');
          return null;
        }
      } else {
        print(
          '❌ Обновление токена не удалось. Код ответа: ${response.statusCode}',
        );
        print('📩 Заголовки ответа: ${response.headers}');
        print('📩 Тело ответа: ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          print('📛 Детали ошибки: $errorData');
        } catch (e) {
          print('⚠️ Не удалось распарсить тело ошибки как JSON: $e');
        }

        await clearAll();
        return null;
      }
    } catch (e) {
      print('❌ Исключение при обновлении токена: $e');
      await clearAll();
      return null;
    }
  }

  Future<void> setAuthenticated(bool isAuthenticated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthenticatedKey, isAuthenticated);
    print('🔐 Статус аутентификации: $isAuthenticated');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAuthenticatedKey) ?? false;
  }

  Future<void> savePinCode(String pinCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinCodeKey, pinCode);
    print('📌 PIN сохранён.');
  }

  Future<String?> getPinCode() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinCodeKey);
    if (pin == null) print('⚠️ PIN отсутствует.');
    return pin;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_accessExpiryKey);
    await prefs.remove(_isAuthenticatedKey);
    await prefs.remove(_pinCodeKey);
    print('🧹 Все данные пользователя удалены из кэша.');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/features/auth/data/models/auth_way.dart';
import 'package:waypay_mobile/features/auth/data/models/call_confirm_request_model.dart';
import 'package:waypay_mobile/features/auth/data/models/start_auth_request_model.dart';
import 'package:waypay_mobile/features/auth/data/models/start_auth_response_model.dart';
import 'package:waypay_mobile/blacklist_plus/features/auth/data/models/auth_way.dart'
    as blacklist_auth;
import 'package:waypay_mobile/blacklist_plus/features/auth/data/models/call_confirm_request_model.dart'
    as blacklist_auth;
import 'package:waypay_mobile/blacklist_plus/features/auth/data/models/start_auth_request_model.dart'
    as blacklist_auth;

void main() {
  test('WhatsApp авторизация отправляет ожидаемые значения API', () {
    expect(
      StartAuthRequestModel(
        phone: '89990000000',
        authWay: AuthWay.whatsAppCode,
      ).toJson(),
      {
        'phone': '89990000000',
        'userType': 'employee',
        'authWay': 'WhatsAppCode',
      },
    );

    expect(
      const CallConfirmRequestModel(
        phone: '89990000000',
        checkId: '123456',
        authWay: AuthWay.whatsAppCode,
      ).toJson(),
      {
        'phone': '89990000000',
        'checkId': '123456',
        'userType': 'employee',
        'authWay': 'WhatsAppCode',
      },
    );
  });

  test('ответ запуска WhatsApp авторизации допускает пустые данные звонка', () {
    final response = StartAuthResponseModel.fromJson({
      'checkId': null,
      'callPhone': null,
    });

    expect(response.checkId, isNull);
    expect(response.callPhone, isNull);
  });

  test('ЧС+ отправляет WhatsApp-способ в snake_case API', () {
    expect(
      blacklist_auth.StartAuthRequestModel(
        phone: '+79990000000',
        authWay: blacklist_auth.AuthWay.whatsAppCode,
      ).toJson(),
      {
        'phone': '+79990000000',
        'user_type': 'blacklist_plus',
        'userType': 'blacklist_plus',
        'auth_way': 'WhatsAppCode',
        'authWay': 'WhatsAppCode',
      },
    );

    expect(
      const blacklist_auth.CallConfirmRequestModel(
        phone: '+79990000000',
        checkId: '123456',
        authWay: blacklist_auth.AuthWay.whatsAppCode,
      ).toJson(),
      {
        'phone': '+79990000000',
        'check_id': '123456',
        'checkId': '123456',
        'user_type': 'blacklist_plus',
        'userType': 'blacklist_plus',
        'auth_way': 'WhatsAppCode',
        'authWay': 'WhatsAppCode',
      },
    );
  });
}

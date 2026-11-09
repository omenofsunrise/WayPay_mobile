import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/features/auth/data/models/auth_way.dart';
import 'package:waypay_mobile/features/auth/data/models/call_confirm_request_model.dart';
import 'package:waypay_mobile/features/auth/data/models/start_auth_request_model.dart';
import 'package:waypay_mobile/features/auth/data/models/start_auth_response_model.dart';

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
}

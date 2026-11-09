import 'package:waypay_mobile/features/auth/data/models/auth_way.dart';

class CallConfirmRequestModel {
  final String? checkId;
  final String? phone;
  final String userType;
  final AuthWay authWay;

  /// Токен устройства FCM. Бэкенд кладёт его в refresh_tokens.firebase_device_id
  /// и по нему потом шлёт пуши. Без него уведомления на это устройство
  /// не придут никогда.
  final String? deviceId;

  const CallConfirmRequestModel({
    this.checkId,
    this.phone,
    this.userType = 'employee',
    this.authWay = AuthWay.callCheck,
    this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'checkId': checkId,
    'phone': phone,
    'userType': userType,
    'authWay': authWay.apiValue,
    if (deviceId != null) 'deviceId': deviceId,
  };
}

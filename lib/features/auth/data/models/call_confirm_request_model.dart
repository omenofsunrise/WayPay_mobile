class CallConfirmRequestModel {
  final String? checkId;
  final String? phone;
  final String userType;

  /// Токен устройства FCM. Бэкенд кладёт его в refresh_tokens.firebase_device_id
  /// и по нему потом шлёт пуши. Без него уведомления на это устройство
  /// не придут никогда.
  final String? deviceId;

  const CallConfirmRequestModel({
    this.checkId,
    this.phone,
    this.userType = 'employee',
    this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'checkId': checkId,
    'phone': phone,
    'userType': userType,
    if (deviceId != null) 'deviceId': deviceId,
  };
}

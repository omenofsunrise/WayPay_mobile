import 'package:waypay_mobile/blacklist_plus/features/auth/data/models/auth_way.dart';

class StartAuthRequestModel {
  final String phone;
  final String userType;
  final AuthWay authWay;

  StartAuthRequestModel({
    required this.phone,
    this.userType = 'blacklist_plus',
    this.authWay = AuthWay.callCheck,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'user_type': userType,
      'userType': userType,
      'auth_way': authWay.apiValue,
      'authWay': authWay.apiValue,
    };
  }
}

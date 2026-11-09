import 'package:waypay_mobile/features/auth/data/models/auth_way.dart';

class StartAuthRequestModel {
  final String phone;
  final String userType;
  final AuthWay authWay;

  StartAuthRequestModel({
    required this.phone,
    this.userType = 'employee',
    this.authWay = AuthWay.callCheck,
  });

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'userType': userType, 'authWay': authWay.apiValue};
  }
}

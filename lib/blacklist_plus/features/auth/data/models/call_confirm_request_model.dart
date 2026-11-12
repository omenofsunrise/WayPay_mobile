import 'package:waypay_mobile/blacklist_plus/features/auth/data/models/auth_way.dart';

class CallConfirmRequestModel {
  final String? checkId;
  final String? name;
  final String? phone;
  final String userType;
  final AuthWay authWay;

  const CallConfirmRequestModel({
    this.checkId,
    this.name,
    this.phone,
    this.userType = 'blacklist_plus',
    this.authWay = AuthWay.callCheck,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'phone': phone,
      'check_id': checkId,
      'checkId': checkId,
      'user_type': userType,
      'userType': userType,
      'auth_way': authWay.apiValue,
      'authWay': authWay.apiValue,
    };
    if (name != null && name!.isNotEmpty) {
      body['name'] = name;
    }
    return body;
  }
}

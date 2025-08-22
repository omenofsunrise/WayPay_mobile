class StartAuthRequestModel {
  final String phone;
  final String userType;

  StartAuthRequestModel({required this.phone, this.userType = 'employee'});

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'userType': userType};
  }
}

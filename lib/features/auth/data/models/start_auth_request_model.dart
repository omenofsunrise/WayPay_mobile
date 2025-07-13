class StartAuthRequestModel {
  final String phone;
  final String userType;

  StartAuthRequestModel({required this.phone, required this.userType});

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'userType': userType};
  }
}

class CallConfirmRequestModel {
  final String? checkId;
  final String? phone;
  final String userType;

  const CallConfirmRequestModel({
    this.checkId,
    this.phone,
    this.userType = 'employee',
  });

  Map<String, dynamic> toJson() => {
    'checkId': checkId,
    'phone': phone,
    'userType': userType,
  };
}

class StartAuthResponseModel {
  final String? checkId;
  final String? callPhone;

  StartAuthResponseModel({required this.checkId, required this.callPhone});

  factory StartAuthResponseModel.fromJson(Map<String, dynamic> json) {
    return StartAuthResponseModel(
      checkId: json['checkId'] as String?,
      callPhone: json['callPhone'] as String?,
    );
  }
}

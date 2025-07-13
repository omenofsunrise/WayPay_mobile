class CallConfirmRequestModel {
  final String? checkId;
  final String? phone;

  CallConfirmRequestModel({this.checkId, this.phone});

  Map<String, dynamic> toJson() {
    return {'checkId': checkId, 'phone': phone};
  }
}

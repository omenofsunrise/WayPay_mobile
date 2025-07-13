class UpdateClientDocRequest {
  final String doc;

  UpdateClientDocRequest({required this.doc});

  Map<String, dynamic> toJson() {
    return {'doc': doc};
  }
}

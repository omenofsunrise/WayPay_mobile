class CreateClientRequest {
  final String fullName;
  final String phone;
  final String doc;
  final String birthdate;
  final String? docIssueDate;
  final String? registrationAddress;

  CreateClientRequest({
    required this.fullName,
    required this.phone,
    required this.doc,
    required this.birthdate,
    this.docIssueDate,
    this.registrationAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'doc': doc,
      'birthdate': birthdate,
      'docIssueDate': docIssueDate,
      'registrationAddress': registrationAddress,
    };
  }
}

class CreateClientRequest {
  final String fullName;
  final String phone;
  final String? secondPhone;
  final String doc;
  final String birthdate;
  final String? docIssueDate;
  final String? registrationAddress;
  final String? actualAddress;

  CreateClientRequest({
    required this.fullName,
    required this.phone,
    this.secondPhone,
    required this.doc,
    required this.birthdate,
    this.docIssueDate,
    this.registrationAddress,
    this.actualAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      if (secondPhone != null) 'secondPhone': secondPhone,
      'doc': doc,
      'birthdate': birthdate,
      'docIssueDate': docIssueDate,
      'registrationAddress': registrationAddress,
      if (actualAddress != null) 'actualAddress': actualAddress,
    };
  }
}

class ClientModel {
  final int id;
  final String fullName;
  final String phone;
  final String doc;
  final DateTime birthdate;
  final int? docIssueYear;
  final String? registrationAddress;
  final List<int> creditIds;
  final List<int> creditRestTerms;
  final double debt;

  ClientModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.doc,
    required this.birthdate,
    this.docIssueYear,
    this.registrationAddress,
    required this.creditIds,
    required this.creditRestTerms,
    required this.debt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      fullName: json['fullName'],
      phone: json['phone'],
      doc: json['doc'],
      birthdate: DateTime.parse(json['birthdate']),
      docIssueYear: json['docIssueYear'],
      registrationAddress: json['registrationAddress'],
      creditIds: List<int>.from(json['creditIds']),
      creditRestTerms: List<int>.from(json['creditRestTerms']),
      debt: (json['debt'] as num).toDouble(),
    );
  }
}

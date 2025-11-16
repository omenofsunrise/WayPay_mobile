class ClientModel {
  final int id;
  final String fullName;
  final String phone;
  final String? secondPhone;
  final String doc;
  final DateTime birthdate;
  final int? docIssueYear;
  final String? registrationAddress;
  final List<int> creditIds;
  final List<int> creditRestTerms;
  final double debt;
  final int? employeeId;
  final bool hasPassportPhoto;
  final bool hasSecondPassportPhoto;

  ClientModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.secondPhone,
    required this.doc,
    required this.birthdate,
    this.docIssueYear,
    this.registrationAddress,
    required this.creditIds,
    required this.creditRestTerms,
    required this.debt,
    this.employeeId,
    this.hasPassportPhoto = false,
    this.hasSecondPassportPhoto = false,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    int? parseDocIssueYear(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        final parsedDate = DateTime.tryParse(value);
        if (parsedDate != null) {
          return parsedDate.year;
        }
        return int.tryParse(value);
      }
      return null;
    }

    List<int> intList(dynamic source) {
      if (source is List) {
        return source.map((e) => (e as num).toInt()).toList();
      }
      return const [];
    }

    return ClientModel(
      id: json['id'],
      fullName: json['fullName'],
      phone: json['phone'],
      secondPhone: json['secondPhone'],
      doc: json['doc'],
      birthdate: DateTime.parse(json['birthdate']),
      docIssueYear: parseDocIssueYear(json['docIssueYear']),
      registrationAddress: json['registrationAddress'],
      creditIds: intList(json['creditIds']),
      creditRestTerms: intList(json['creditRestTerms']),
      debt: (json['debt'] as num).toDouble(),
      employeeId: json['employeeId'],
      hasPassportPhoto: json['hasPassportPhoto'] as bool? ?? false,
      hasSecondPassportPhoto: json['hasSecondPassportPhoto'] as bool? ?? false,
    );
  }
}

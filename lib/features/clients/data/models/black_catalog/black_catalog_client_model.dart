class BlackCatalogClientModel {
  const BlackCatalogClientModel({
    required this.id,
    this.fullName,
    this.doc,
    this.docIssueDate,
    this.phone,
    this.birthdate,
    this.address,
  });

  final int id;
  final String? fullName;
  final String? doc;
  final DateTime? docIssueDate;
  final String? phone;
  final DateTime? birthdate;
  final String? address;

  factory BlackCatalogClientModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return BlackCatalogClientModel(
      id: parseId(json['id']),
      fullName: json['fullName'] as String?,
      doc: json['doc'] as String?,
      docIssueDate: parseDate(json['docIssueDate']),
      phone: json['phone'] as String?,
      birthdate: parseDate(json['birthdate']),
      address: json['address'] as String?,
    );
  }
}

class CompanyCreateRequest {
  final String adminPhone;
  final String adminName;
  final String companyName;
  final String licenceDate;

  CompanyCreateRequest({
    required this.adminPhone,
    required this.adminName,
    required this.companyName,
    required this.licenceDate,
  });

  Map<String, dynamic> toJson() => {
    'adminPhone': adminPhone,
    'adminName': adminName,
    'companyName': companyName,
    'licenceDate': licenceDate,
  };
}

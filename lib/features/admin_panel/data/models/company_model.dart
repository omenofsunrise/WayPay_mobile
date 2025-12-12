class CompanyModel {
  final int id;
  final String name;
  final String chief;
  final String phone;
  final String city;
  final String officeAddress;
  final String bank;
  final String email;
  final String? photoPath;
  final DateTime licenceDate;
  final int? currentBankCardId;
  final String? supportPhone;
  final String inn;

  CompanyModel({
    required this.id,
    required this.name,
    required this.chief,
    required this.phone,
    required this.city,
    required this.officeAddress,
    required this.bank,
    required this.email,
    required this.licenceDate,
    this.photoPath,
    this.currentBankCardId,
    this.supportPhone,
    this.inn = '',
  });

  CompanyModel copyWith({
    String? name,
    String? chief,
    String? phone,
    String? city,
    String? officeAddress,
    String? bank,
    String? email,
    DateTime? licenceDate,
    String? photoPath,
    int? currentBankCardId,
    String? supportPhone,
    String? inn,
  }) {
    return CompanyModel(
      id: id,
      name: name ?? this.name,
      chief: chief ?? this.chief,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      officeAddress: officeAddress ?? this.officeAddress,
      bank: bank ?? this.bank,
      email: email ?? this.email,
      licenceDate: licenceDate ?? this.licenceDate,
      photoPath: photoPath ?? this.photoPath,
      currentBankCardId: currentBankCardId ?? this.currentBankCardId,
      supportPhone: supportPhone ?? this.supportPhone,
      inn: inn ?? this.inn,
    );
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'],
      name: json['name'] ?? '',
      chief: json['chief'] ?? '',
      phone: json['phone'] ?? '',
      city: json['city'] ?? '',
      officeAddress: json['officeAddress'] ?? '',
      bank: json['bank'] ?? '',
      email: json['email'] ?? '',
      photoPath: json['photoPath'],
      licenceDate:
          DateTime.tryParse(json['licenceDate'] ?? '') ?? DateTime.now(),
      currentBankCardId: json['currentBankCardId'],
      supportPhone: json['supportPhone'],
      inn: json['inn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'chief': chief,
    'phone': phone,
    'city': city,
    'officeAddress': officeAddress,
    'bank': bank,
    'email': email,
    'photoPath': photoPath,
    'licenceDate': licenceDate.toIso8601String(),
    'currentBankCardId': currentBankCardId,
    'supportPhone': supportPhone,
    'inn': inn,
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'chief': chief,
    'phone': phone,
    'city': city,
    'officeAddress': officeAddress,
    'bank': bank,
    'email': email,
    'currentBankCardId': currentBankCardId,
    'supportPhone': supportPhone,
    'inn': inn,
  };
}

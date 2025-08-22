class CompanyModel {
  final int id;
  final String name;
  final String chief;
  final String phone;
  final String city;
  final String officeAddress;
  final String bank;
  final String inn;
  final String email;
  final String? photoPath;
  final DateTime licenceDate;

  CompanyModel({
    required this.id,
    required this.name,
    required this.chief,
    required this.phone,
    required this.city,
    required this.officeAddress,
    required this.bank,
    required this.inn,
    required this.email,
    required this.licenceDate,
    this.photoPath,
  });

  CompanyModel copyWith({
    String? name,
    String? chief,
    String? phone,
    String? city,
    String? officeAddress,
    String? bank,
    String? inn,
    String? email,
    DateTime? licenceDate,
    String? photoPath,
  }) {
    return CompanyModel(
      id: id,
      name: name ?? this.name,
      chief: chief ?? this.chief,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      officeAddress: officeAddress ?? this.officeAddress,
      bank: bank ?? this.bank,
      inn: inn ?? this.inn,
      email: email ?? this.email,
      licenceDate: licenceDate ?? this.licenceDate,
      photoPath: photoPath ?? this.photoPath,
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
      inn: json['inn'] ?? '',
      email: json['email'] ?? '',
      photoPath: json['photoPath'],
      licenceDate:
          DateTime.tryParse(json['licenceDate'] ?? '') ?? DateTime.now(),
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
    'inn': inn,
    'email': email,
    'photoPath': photoPath,
    'licenceDate': licenceDate.toIso8601String(),
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'chief': chief,
    'phone': phone,
    'city': city,
    'officeAddress': officeAddress,
    'bank': bank,
    'inn': inn,
    'email': email,
  };
}

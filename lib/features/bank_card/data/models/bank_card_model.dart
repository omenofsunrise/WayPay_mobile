class BankCardModel {
  final int id;
  final String? phone;
  final String? details;

  BankCardModel({
    required this.id,
    this.phone,
    this.details,
  });

  factory BankCardModel.fromJson(Map<String, dynamic> json) {
    return BankCardModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String?,
      details: json['details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'details': details,
    };
  }
}

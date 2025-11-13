class SoldProductModel {
  final int id;
  final int creditId;
  final String name;
  final double price;
  final double? surcharge; // Может быть null
  final double? surchargeAmount; // Может быть null

  SoldProductModel({
    required this.id,
    required this.creditId,
    required this.name,
    required this.price,
    this.surcharge,
    this.surchargeAmount,
  });

  factory SoldProductModel.fromJson(Map<String, dynamic> json) {
    return SoldProductModel(
      id: json['id'],
      creditId: json['creditId'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      surcharge: json['surcharge'] != null
          ? (json['surcharge'] as num).toDouble()
          : null,
      surchargeAmount: json['surchargeAmount'] != null
          ? (json['surchargeAmount'] as num).toDouble()
          : null,
    );
  }

  double get totalAmount {
    final baseAmount = price;
    var additionalAmount =
        surchargeAmount ?? (baseAmount * surcharge! / 100) ?? 0.0;
    return baseAmount + additionalAmount;
  }

  bool get hasSurcharge => surcharge != null || surchargeAmount != null;
}

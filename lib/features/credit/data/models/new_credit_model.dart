class CreateCreditRequest {
  int? clientId;
  String name;
  int? creditTypeId;
  int? creditTabTypeId;

  int? guarantorClientId;
  Guarantor? guarantor;

  int? investorId;
  int? poolId;
  DateTime creditDate;
  DateTime startPaymentDay;
  double firstPayment;
  int termMonths;
  bool inDebt;
  String? debtComment;
  List<CreditProduct> products;

  CreateCreditRequest({
    this.clientId,
    required this.name,
    this.creditTypeId,
    this.creditTabTypeId,
    this.guarantorClientId,
    this.guarantor,
    this.investorId,
    this.poolId,
    required this.creditDate,
    required this.startPaymentDay,
    required this.firstPayment,
    required this.termMonths,
    required this.inDebt,
    this.debtComment,
    required this.products,
  });

  CreateCreditRequest copyWith({
    int? clientId,
    String? name,
    int? creditTypeId,
    int? creditTabTypeId,
    int? guarantorClientId,
    Guarantor? guarantor,
    int? investorId,
    int? poolId,
    DateTime? creditDate,
    DateTime? startPaymentDay,
    double? firstPayment,
    int? termMonths,
    bool? inDebt,
    String? debtComment,
    List<CreditProduct>? products,
    bool clearCreditTypeId = false,
    bool clearCreditTabTypeId = false,
  }) {
    return CreateCreditRequest(
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      creditTypeId: clearCreditTypeId ? null : (creditTypeId ?? this.creditTypeId),
      creditTabTypeId: clearCreditTabTypeId ? null : (creditTabTypeId ?? this.creditTabTypeId),
      guarantorClientId: guarantorClientId ?? this.guarantorClientId,
      guarantor: guarantor ?? this.guarantor,
      investorId: investorId ?? this.investorId,
      poolId: poolId ?? this.poolId,
      creditDate: creditDate ?? this.creditDate,
      startPaymentDay: startPaymentDay ?? this.startPaymentDay,
      firstPayment: firstPayment ?? this.firstPayment,
      termMonths: termMonths ?? this.termMonths,
      inDebt: inDebt ?? this.inDebt,
      debtComment: debtComment ?? this.debtComment,
      products: products ?? this.products,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'clientId': clientId,
      'name': name,
      'creditTypeId': creditTypeId,
      'creditTabTypeId': creditTabTypeId,
      'investorId': investorId,
      'poolId': poolId,
      'creditDate': creditDate.toIso8601String(),
      'startPaymentDay': startPaymentDay.toIso8601String(),
      'firstPayment': firstPayment,
      'termMonths': termMonths,
      'inDebt': inDebt,
      'debtComment': debtComment,
      'products': products.map((p) => p.toJson()).toList(),
    };
    if (guarantorClientId != null) {
      map['guarantorClientId'] = guarantorClientId;
    }
    if (guarantor != null && guarantorClientId == null) {
      map['guarantor'] = guarantor!.toJson();
    }
    return map;
  }
}

class Guarantor {
  final String fullName;
  final String phone;
  final DateTime? birthdate;
  final String? address;
  final String? doc;

  Guarantor({
    required this.fullName,
    required this.phone,
    this.birthdate,
    this.address,
    this.doc,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'birthdate': birthdate?.toIso8601String(),
      'address': address,
      'doc': doc,
    };
  }
}

class CreditProduct {
  final String name;
  final double price;
  final int quantity;
  final double? surcharge;
  final double? surchargeAmount;

  CreditProduct({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.surcharge,
    this.surchargeAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'surcharge': surcharge,
      'surchargeAmount': surchargeAmount,
    };
  }

  CreditProduct copyWith({
    String? name,
    double? price,
    int? quantity,
    double? surcharge,
    double? surchargeAmount,
  }) {
    return CreditProduct(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      surcharge: surcharge ?? this.surcharge,
      surchargeAmount: surchargeAmount ?? this.surchargeAmount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditProduct &&
        other.name == name &&
        other.price == price &&
        other.quantity == quantity &&
        other.surcharge == surcharge &&
        other.surchargeAmount == surchargeAmount;
  }

  @override
  int get hashCode {
    return Object.hash(name, price, quantity, surcharge, surchargeAmount);
  }
}

class CreateCreditRequest {
  int? clientId;
  String name;
  int creditTypeId;
  int creditTabTypeId;

  int guarantorClientId;
  Guarantor? guarantor;

  int? investorId;
  int? poolId;
  DateTime creditDate;
  double firstPayment;
  int termMonths;
  int paymentDay;
  bool nextMonthStart;
  bool inDebt;
  String? debtComment;
  List<CreditProduct> products;

  CreateCreditRequest({
    this.clientId,
    required this.name,
    required this.creditTypeId,
    required this.creditTabTypeId,
    required this.guarantorClientId,
    this.guarantor,
    this.investorId,
    this.poolId,
    required this.creditDate,
    required this.firstPayment,
    required this.termMonths,
    required this.paymentDay,
    required this.nextMonthStart,
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
    double? firstPayment,
    int? termMonths,
    int? paymentDay,
    bool? nextMonthStart,
    bool? inDebt,
    String? debtComment,
    List<CreditProduct>? products,
  }) {
    return CreateCreditRequest(
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      creditTypeId: creditTypeId ?? this.creditTypeId,
      creditTabTypeId: creditTabTypeId ?? this.creditTabTypeId,
      guarantorClientId: guarantorClientId ?? this.guarantorClientId,
      guarantor: guarantor ?? this.guarantor,
      investorId: investorId ?? this.investorId,
      poolId: poolId ?? this.poolId,
      creditDate: creditDate ?? this.creditDate,
      firstPayment: firstPayment ?? this.firstPayment,
      termMonths: termMonths ?? this.termMonths,
      paymentDay: paymentDay ?? this.paymentDay,
      nextMonthStart: nextMonthStart ?? this.nextMonthStart,
      inDebt: inDebt ?? this.inDebt,
      debtComment: debtComment ?? this.debtComment,
      products: products ?? this.products,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'name': name,
      'creditTypeId': creditTypeId,
      'creditTabTypeId': creditTabTypeId,
      'guarantorClientId': guarantorClientId,
      'guarantor': guarantor?.toJson(),
      'investorId': investorId,
      'poolId': poolId,
      'creditDate': creditDate.toIso8601String(),
      'firstPayment': firstPayment,
      'termMonths': termMonths,
      'paymentDay': paymentDay,
      'nextMonthStart': nextMonthStart,
      'inDebt': inDebt,
      'debtComment': debtComment,
      'products': products.map((p) => p.toJson()).toList(),
    };
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
  final double? surcharge;
  final double? surchargeAmount;

  CreditProduct({
    required this.name,
    required this.price,
    this.surcharge,
    this.surchargeAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'surcharge': surcharge,
      'surchargeAmount': surchargeAmount,
    };
  }
}

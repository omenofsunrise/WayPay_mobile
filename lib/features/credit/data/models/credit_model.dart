class CreditModel {
  final int id;
  final DateTime creditDate;
  final num totalAmount;
  final bool isActive;
  final bool isFavourite;
  final int clientId;
  final int? investorId;
  final int? guarantorId;
  final int termMonths;
  final String clientFullName;
  final String investorNickname;
  final String clientPhone;
  final num firstPayment;
  final num accured;
  final num payed;
  final num rest;
  final num currentMonthDebt;
  final num debt;
  final num incomeRubles;
  final num incomePercents;
  final String employeeName;

  CreditModel({
    required this.id,
    required this.creditDate,
    required this.totalAmount,
    required this.isActive,
    required this.isFavourite,
    required this.clientId,
    this.investorId,
    this.guarantorId,
    required this.termMonths,
    required this.clientFullName,
    required this.investorNickname,
    required this.clientPhone,
    required this.firstPayment,
    required this.accured,
    required this.payed,
    required this.rest,
    required this.currentMonthDebt,
    required this.debt,
    required this.incomeRubles,
    required this.incomePercents,
    required this.employeeName,
  });

  factory CreditModel.fromJson(Map<String, dynamic> json) {
    return CreditModel(
      id: (json['id'] as num).toInt(),
      creditDate: DateTime.parse(json['creditDate'] as String),
      totalAmount: json['totalAmount'] as num,
      isActive: json['isActive'] as bool,
      isFavourite: json['isFavourite'] as bool,
      clientId: (json['clientId'] as num).toInt(),
      investorId: (json['investorId'] as num?)?.toInt(),
      guarantorId: (json['guarantorId'] as num?)?.toInt(),
      termMonths: (json['termMonths'] as num).toInt(),
      clientFullName: json['clientFullName'] as String,
      investorNickname: json['investorNickname'] as String,
      clientPhone: json['clientPhone'] as String,
      firstPayment: json['firstPayment'] as num,
      accured: json['accured'] as num,
      payed: json['payed'] as num,
      rest: json['rest'] as num,
      currentMonthDebt: json['currentMonthDebt'] as num,
      debt: json['debt'] as num,
      incomeRubles: json['incomeRubles'] as num,
      incomePercents: json['incomePercents'] as num,
      employeeName: json['employeeName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditDate': creditDate.toIso8601String(),
      'totalAmount': totalAmount,
      'isActive': isActive,
      'isFavourite': isFavourite,
      'clientId': clientId,
      'investorId': investorId,
      'guarantorId': guarantorId,
      'termMonths': termMonths,
      'clientFullName': clientFullName,
      'investorNickname': investorNickname,
      'clientPhone': clientPhone,
      'firstPayment': firstPayment,
      'accured': accured,
      'payed': payed,
      'rest': rest,
      'currentMonthDebt': currentMonthDebt,
      'debt': debt,
      'incomeRubles': incomeRubles,
      'incomePercents': incomePercents,
      'employeeName': employeeName,
    };
  }

  static const _u = Object();

  CreditModel copyWith({
    int? id,
    DateTime? creditDate,
    num? totalAmount,
    bool? isActive,
    bool? isFavourite,
    int? clientId,
    Object? investorId = _u,
    int? guarantorId,
    int? termMonths,
    String? clientFullName,
    String? investorNickname,
    String? clientPhone,
    num? firstPayment,
    num? accured,
    num? payed,
    num? rest,
    num? currentMonthDebt,
    num? debt,
    num? incomeRubles,
    num? incomePercents,
    String? employeeName,
  }) {
    return CreditModel(
      id: id ?? this.id,
      creditDate: creditDate ?? this.creditDate,
      totalAmount: totalAmount ?? this.totalAmount,
      isActive: isActive ?? this.isActive,
      isFavourite: isFavourite ?? this.isFavourite,
      clientId: clientId ?? this.clientId,
      investorId: identical(investorId, _u)
          ? this.investorId
          : investorId as int?,
      guarantorId: guarantorId ?? this.guarantorId,
      termMonths: termMonths ?? this.termMonths,
      clientFullName: clientFullName ?? this.clientFullName,
      investorNickname: investorNickname ?? this.investorNickname,
      clientPhone: clientPhone ?? this.clientPhone,
      firstPayment: firstPayment ?? this.firstPayment,
      accured: accured ?? this.accured,
      payed: payed ?? this.payed,
      rest: rest ?? this.rest,
      currentMonthDebt: currentMonthDebt ?? this.currentMonthDebt,
      debt: debt ?? this.debt,
      incomeRubles: incomeRubles ?? this.incomeRubles,
      incomePercents: incomePercents ?? this.incomePercents,
      employeeName: employeeName ?? this.employeeName,
    );
  }
}

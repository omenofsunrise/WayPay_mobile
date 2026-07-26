class CreditModel {
  final int id;
  final String? name;
  final String? creditTypeName;
  final String? status;
  final DateTime creditDate;
  final num totalAmount;
  final num? totalClean;
  final bool isActive;
  final bool isFavourite;
  final bool terminated;
  final int clientId;
  final int? investorId;
  final int? poolId;
  final int? guarantorId;
  final String? guarantorFullName;
  final String? guarantorPhone;
  final String? guarantorBirthdate;
  final String? guarantorAddress;
  final String? guarantorDoc;
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
  final String? debtComment;
  final int? debtDays;
  final num? defferedIncome;
  final num incomeRubles;
  final num incomePercents;
  final String employeeName;

  CreditModel({
    required this.id,
    this.name,
    this.creditTypeName,
    this.status,
    required this.creditDate,
    required this.totalAmount,
    this.totalClean,
    required this.isActive,
    required this.isFavourite,
    this.terminated = false,
    required this.clientId,
    this.investorId,
    this.poolId,
    this.guarantorId,
    this.guarantorFullName,
    this.guarantorPhone,
    this.guarantorBirthdate,
    this.guarantorAddress,
    this.guarantorDoc,
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
    this.debtComment,
    this.debtDays,
    this.defferedIncome,
    required this.incomeRubles,
    required this.incomePercents,
    required this.employeeName,
  });

  factory CreditModel.fromJson(Map<String, dynamic> json) {
    final creditDateRaw = json['creditDate'];
    DateTime creditDate;
    if (creditDateRaw is String && creditDateRaw.isNotEmpty) {
      creditDate = DateTime.parse(creditDateRaw);
    } else {
      creditDate = DateTime.fromMillisecondsSinceEpoch(0);
    }

    // Гарант может приходить как плоские поля (guarantorFullname/...) или
    // как вложенный объект guarantor { fullName, phone, ... } — берём любой.
    final guarantor = json['guarantor'] as Map<String, dynamic>?;
    String? gField(List<String> flatKeys, String nestedKey) {
      for (final k in flatKeys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
      }
      final n = guarantor?[nestedKey];
      if (n is String && n.isNotEmpty) return n;
      if (n != null) return n.toString();
      return null;
    }

    num numOr(dynamic v, [num fallback = 0]) => v is num ? v : fallback;

    return CreditModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String?,
      creditTypeName: json['creditTypeName'] as String?,
      status: json['status'] as String?,
      creditDate: creditDate,
      totalAmount: numOr(json['totalAmount']),
      totalClean: json['totalClean'] as num?,
      isActive: json['isActive'] as bool? ?? true,
      isFavourite: json['isFavourite'] as bool? ?? false,
      terminated: json['terminated'] as bool? ?? false,
      clientId: (json['clientId'] as num?)?.toInt() ?? 0,
      investorId: (json['investorId'] as num?)?.toInt(),
      poolId: (json['poolId'] as num?)?.toInt(),
      guarantorId: (json['guarantorId'] as num?)?.toInt(),
      guarantorFullName: gField([
        'guarantorFullname',
        'guarantorFullName',
      ], 'fullName'),
      guarantorPhone: gField(['guarantorPhone'], 'phone'),
      guarantorBirthdate: gField(['guarantorBirthdate'], 'birthdate'),
      guarantorAddress: gField(['guarantorAddress'], 'address'),
      guarantorDoc: gField(['guarantorDoc'], 'doc'),
      termMonths: (json['termMonths'] as num?)?.toInt() ?? 0,
      clientFullName: json['clientFullName'] as String? ?? '',
      investorNickname: json['investorNickname'] as String? ?? '',
      clientPhone: json['clientPhone'] as String? ?? '',
      firstPayment: numOr(json['firstPayment']),
      accured: numOr(json['accured']),
      payed: numOr(json['payed']),
      rest: numOr(json['rest']),
      currentMonthDebt: numOr(json['currentMonthDebt']),
      debt: numOr(json['debt']),
      debtComment: json['debtComment'] as String?,
      debtDays: (json['debtDays'] as num?)?.toInt(),
      defferedIncome: json['defferedIncome'] as num?,
      incomeRubles: numOr(json['incomeRubles']),
      incomePercents: numOr(json['incomePercents']),
      employeeName: json['employeeName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creditTypeName': creditTypeName,
      'status': status,
      'creditDate': creditDate.toIso8601String(),
      'totalAmount': totalAmount,
      'totalClean': totalClean,
      'isActive': isActive,
      'isFavourite': isFavourite,
      'terminated': terminated,
      'clientId': clientId,
      'investorId': investorId,
      'poolId': poolId,
      'guarantorId': guarantorId,
      'guarantorFullName': guarantorFullName,
      'guarantorPhone': guarantorPhone,
      'guarantorBirthdate': guarantorBirthdate,
      'guarantorAddress': guarantorAddress,
      'guarantorDoc': guarantorDoc,
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
      'debtComment': debtComment,
      'debtDays': debtDays,
      'defferedIncome': defferedIncome,
      'incomeRubles': incomeRubles,
      'incomePercents': incomePercents,
      'employeeName': employeeName,
    };
  }

  static const _u = Object();

  CreditModel copyWith({
    int? id,
    String? name,
    String? creditTypeName,
    String? status,
    DateTime? creditDate,
    num? totalAmount,
    num? totalClean,
    bool? isActive,
    bool? isFavourite,
    bool? terminated,
    int? clientId,
    Object? investorId = _u,
    int? poolId,
    int? guarantorId,
    String? guarantorFullName,
    String? guarantorPhone,
    String? guarantorBirthdate,
    String? guarantorAddress,
    String? guarantorDoc,
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
    String? debtComment,
    int? debtDays,
    num? defferedIncome,
    num? incomeRubles,
    num? incomePercents,
    String? employeeName,
  }) {
    return CreditModel(
      id: id ?? this.id,
      name: name ?? this.name,
      creditTypeName: creditTypeName ?? this.creditTypeName,
      status: status ?? this.status,
      creditDate: creditDate ?? this.creditDate,
      totalAmount: totalAmount ?? this.totalAmount,
      totalClean: totalClean ?? this.totalClean,
      isActive: isActive ?? this.isActive,
      isFavourite: isFavourite ?? this.isFavourite,
      terminated: terminated ?? this.terminated,
      clientId: clientId ?? this.clientId,
      investorId: identical(investorId, _u)
          ? this.investorId
          : investorId as int?,
      poolId: poolId ?? this.poolId,
      guarantorId: guarantorId ?? this.guarantorId,
      guarantorFullName: guarantorFullName ?? this.guarantorFullName,
      guarantorPhone: guarantorPhone ?? this.guarantorPhone,
      guarantorBirthdate: guarantorBirthdate ?? this.guarantorBirthdate,
      guarantorAddress: guarantorAddress ?? this.guarantorAddress,
      guarantorDoc: guarantorDoc ?? this.guarantorDoc,
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
      debtComment: debtComment ?? this.debtComment,
      debtDays: debtDays ?? this.debtDays,
      defferedIncome: defferedIncome ?? this.defferedIncome,
      incomeRubles: incomeRubles ?? this.incomeRubles,
      incomePercents: incomePercents ?? this.incomePercents,
      employeeName: employeeName ?? this.employeeName,
    );
  }
}

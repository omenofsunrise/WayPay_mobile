class EmployeeModel {
  final String? fullname;
  final String? avatar;

  // analytic
  final num? currentIncome;
  final num? expectedIncome;

  //payments
  final num? approvedPaymentsAmount;
  final num? disapprovePaymentsAmount;

  // credits
  final int? closedCreditsCount;
  final int? activeCreditsCount;

  // clients
  final int? clientsCount;
  final int? creditApplicationCount;
  final int? queuesCount;
  final int? creditsCount;
  final int? blacklistCount;

  // investors
  final num? balance;
  final num? investment;

  // budget
  final num? budgetIncome;
  final num? budgetOutcome;

  // companies
  final int? companiesCount;
  final int? activeCompaniesCount;

  EmployeeModel({
    this.fullname,
    this.avatar,
    this.currentIncome,
    this.expectedIncome,
    this.approvedPaymentsAmount,
    this.disapprovePaymentsAmount,
    this.closedCreditsCount,
    this.activeCreditsCount,
    this.clientsCount,
    this.creditApplicationCount,
    this.queuesCount,
    this.creditsCount,
    this.blacklistCount,
    this.balance,
    this.investment,
    this.budgetIncome,
    this.budgetOutcome,
    this.companiesCount,
    this.activeCompaniesCount,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      fullname: json['fullname'] as String?,
      avatar: json['avatar'] as String?,
      currentIncome: json['currentIncome'] as num?,
      expectedIncome: json['expectedIncome'] as num?,
      approvedPaymentsAmount: json['approvedPaymentsAmount'] as num?,
      disapprovePaymentsAmount: json['disapprovePaymentsAmount'] as num?,
      closedCreditsCount: (json['closedCreditsCount'] as num?)?.toInt(),
      activeCreditsCount: (json['activeCreditsCount'] as num?)?.toInt(),
      clientsCount: (json['clientsCount'] as num?)?.toInt(),
      creditApplicationCount: (json['creditApplicationCount'] as num?)?.toInt(),
      queuesCount: (json['queuesCount'] as num?)?.toInt(),
      creditsCount: (json['creditsCount'] as num?)?.toInt(),
      blacklistCount: (json['blacklistCount'] as num?)?.toInt(),
      balance: json['balance'] as num?,
      investment: json['investment'] as num?,
      budgetIncome: json['budgetIncome'] as num?,
      budgetOutcome: json['budgetOutcome'] as num?,
      companiesCount: (json['companiesCount'] as num?)?.toInt(),
      activeCompaniesCount: (json['activeCompaniesCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullname': fullname,
      'avatar': avatar,
      'currentIncome': currentIncome,
      'expectedIncome': expectedIncome,
      'approvedPaymentsAmount': approvedPaymentsAmount,
      'disapprovePaymentsAmount': disapprovePaymentsAmount,
      'closedCreditsCount': closedCreditsCount,
      'activeCreditsCount': activeCreditsCount,
      'clientsCount': clientsCount,
      'creditApplicationCount': creditApplicationCount,
      'queuesCount': queuesCount,
      'creditsCount': creditsCount,
      'blacklistCount': blacklistCount,
      'balance': balance,
      'investment': investment,
      'budgetIncome': budgetIncome,
      'budgetOutcome': budgetOutcome,
      'companiesCount': companiesCount,
      'activeCompaniesCount': activeCompaniesCount,
    };
  }

  EmployeeModel copyWith({
    String? fullname,
    String? avatar,
    num? currentIncome,
    num? expectedIncome,
    num? approvedPaymentsAmount,
    num? disapprovePaymentsAmount,
    int? closedCreditsCount,
    int? activeCreditsCount,
    int? clientsCount,
    int? creditApplicationCount,
    int? queuesCount,
    int? creditsCount,
    int? blacklistCount,
    num? balance,
    num? investment,
    num? budgetIncome,
    num? budgetOutcome,
    int? companiesCount,
    int? activeCompaniesCount,
  }) {
    return EmployeeModel(
      fullname: fullname ?? this.fullname,
      avatar: avatar ?? this.avatar,
      currentIncome: currentIncome ?? this.currentIncome,
      expectedIncome: expectedIncome ?? this.expectedIncome,
      approvedPaymentsAmount:
          approvedPaymentsAmount ?? this.approvedPaymentsAmount,
      disapprovePaymentsAmount:
          disapprovePaymentsAmount ?? this.disapprovePaymentsAmount,
      closedCreditsCount: closedCreditsCount ?? this.closedCreditsCount,
      activeCreditsCount: activeCreditsCount ?? this.activeCreditsCount,
      clientsCount: clientsCount ?? this.clientsCount,
      creditApplicationCount:
          creditApplicationCount ?? this.creditApplicationCount,
      queuesCount: queuesCount ?? this.queuesCount,
      creditsCount: creditsCount ?? this.creditsCount,
      blacklistCount: blacklistCount ?? this.blacklistCount,
      balance: balance ?? this.balance,
      investment: investment ?? this.investment,
      budgetIncome: budgetIncome ?? this.budgetIncome,
      budgetOutcome: budgetOutcome ?? this.budgetOutcome,
      companiesCount: companiesCount ?? this.companiesCount,
      activeCompaniesCount: activeCompaniesCount ?? this.activeCompaniesCount,
    );
  }
}

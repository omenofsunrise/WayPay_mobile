class InvestorsModel {
  final int id;
  final String nickname;
  final String fullName;
  final String? phoneNumber;
  final int investorPie;
  final double investmentAmount;
  final double balance;
  final bool isBlocked;
  final DateTime? createdAt;
  final double? investment;
  final int? activeCreditsAmount;
  final double? investorIncome;
  final double? selfIncome;
  final bool? isCompany;
  final double? cashbox;
  final DateTime? contractEndDate;

  InvestorsModel({
    required this.id,
    required this.nickname,
    required this.fullName,
    this.phoneNumber,
    required this.investorPie,
    required this.investmentAmount,
    required this.balance,
    required this.isBlocked,
    this.createdAt,
    this.investment,
    this.activeCreditsAmount,
    this.investorIncome,
    this.selfIncome,
    this.isCompany,
    this.cashbox,
    this.contractEndDate,
  });

  factory InvestorsModel.fromJson(Map<String, dynamic> json) {
    return InvestorsModel(
      id: json['id'] as int,
      nickname: json['nickname'] ?? json['nickName'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      investorPie: json['investorPie'] as int? ?? 0,
      investmentAmount: (json['investmentAmount'] ?? json['investment'] ?? 0)
          .toDouble(),
      balance: (json['balance'] as num).toDouble(),
      isBlocked: json['isBlocked'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      investment: json['investment'] != null
          ? (json['investment'] as num).toDouble()
          : null,
      activeCreditsAmount: json['activeCreditsAmount'] as int?,
      investorIncome: json['investorIncome'] != null
          ? (json['investorIncome'] as num).toDouble()
          : null,
      selfIncome: json['selfIncome'] != null
          ? (json['selfIncome'] as num).toDouble()
          : null,
      isCompany: json['isCompany'] as bool?,
      cashbox: json['cashbox'] != null
          ? (json['cashbox'] as num).toDouble()
          : null,
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.tryParse(json['contractEndDate'])
          : null,
    );
  }

  InvestorsModel copyWith({
    int? id,
    String? nickname,
    String? fullName,
    String? phoneNumber,
    int? investorPie,
    double? investmentAmount,
    double? balance,
    bool? isBlocked,
    DateTime? createdAt,
    double? investment,
    int? activeCreditsAmount,
    double? investorIncome,
    double? selfIncome,
    bool? isCompany,
    double? cashbox,
    DateTime? contractEndDate,
  }) {
    return InvestorsModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      investorPie: investorPie ?? this.investorPie,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      balance: balance ?? this.balance,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      investment: investment ?? this.investment,
      activeCreditsAmount: activeCreditsAmount ?? this.activeCreditsAmount,
      investorIncome: investorIncome ?? this.investorIncome,
      selfIncome: selfIncome ?? this.selfIncome,
      isCompany: isCompany ?? this.isCompany,
      cashbox: cashbox ?? this.cashbox,
      contractEndDate: contractEndDate ?? this.contractEndDate,
    );
  }
}

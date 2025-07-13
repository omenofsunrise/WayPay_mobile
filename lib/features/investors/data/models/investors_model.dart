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
    );
  }
}

class CreateBudgetIncomeDto {
  final double amount;
  final String? comment;
  final int investorId;
  final int? companyShare;

  CreateBudgetIncomeDto({
    required this.amount,
    this.comment,
    required this.investorId,
    this.companyShare,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'amount': amount,
      'comment': comment,
      'investorId': investorId,
    };
    if (companyShare != null) {
      data['companyShare'] = companyShare;
    }
    return data;
  }
}

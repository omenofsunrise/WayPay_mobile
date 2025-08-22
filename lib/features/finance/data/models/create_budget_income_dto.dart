class CreateBudgetIncomeDto {
  final double amount;
  final String? comment;
  final int investorId;

  CreateBudgetIncomeDto({
    required this.amount,
    this.comment,
    required this.investorId,
  });

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'comment': comment, 'investorId': investorId};
  }
}

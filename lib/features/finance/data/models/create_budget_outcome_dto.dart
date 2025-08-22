class CreateBudgetOutcomeDto {
  final double amount;
  final String? comment;

  CreateBudgetOutcomeDto({required this.amount, this.comment});

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'comment': comment};
  }
}

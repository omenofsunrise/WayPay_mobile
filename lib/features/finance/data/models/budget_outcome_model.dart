class BudgetOutcomeModel {
  final int id;
  final double amount;
  final String? comment;
  final DateTime createdAt;

  BudgetOutcomeModel({
    required this.id,
    required this.amount,
    this.comment,
    required this.createdAt,
  });

  factory BudgetOutcomeModel.fromJson(Map<String, dynamic> json) {
    return BudgetOutcomeModel(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['date'] as String),
    );
  }
}

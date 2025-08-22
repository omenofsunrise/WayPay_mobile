class BudgetIncomeModel {
  final int id;
  final double amount;
  final String? comment;
  final int investorId;
  final DateTime? createdAt;

  BudgetIncomeModel({
    required this.id,
    required this.amount,
    this.comment,
    required this.investorId,
    required this.createdAt,
  });

  factory BudgetIncomeModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['date'] as String?;
    DateTime? createdAt;

    if (createdAtRaw != null && createdAtRaw.trim().isNotEmpty) {
      createdAt = DateTime.parse(createdAtRaw);
    } else {
      createdAt = null;
    }

    return BudgetIncomeModel(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      comment: json['comment'] as String?,
      investorId: json['investorId'] as int,
      createdAt: createdAt,
    );
  }
}

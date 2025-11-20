class InvestorPoolModel {
  const InvestorPoolModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.selfIncome,
    required this.createdAt,
    this.activeUntil,
  });

  final int id;
  final String name;
  final double balance;
  final double selfIncome;
  final DateTime createdAt;
  final DateTime? activeUntil;

  factory InvestorPoolModel.fromJson(Map<String, dynamic> json) {
    return InvestorPoolModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      selfIncome: (json['selfIncome'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      activeUntil: json['activeUntil'] != null
          ? DateTime.tryParse(json['activeUntil'] as String)
          : null,
    );
  }
}

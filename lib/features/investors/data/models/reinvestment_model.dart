class ReinvestmentModel {
  const ReinvestmentModel({
    required this.id,
    required this.investorId,
    required this.date,
    required this.amount,
    required this.investorNickname,
  });

  final int id;
  final int investorId;
  final DateTime date;
  final double amount;
  final String investorNickname;

  factory ReinvestmentModel.fromJson(Map<String, dynamic> json) {
    return ReinvestmentModel(
      id: (json['id'] as num).toInt(),
      investorId: (json['investorId'] as num?)?.toInt() ?? 0,
      date:
          DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      investorNickname: json['investorNickname'] as String? ?? '—',
    );
  }
}

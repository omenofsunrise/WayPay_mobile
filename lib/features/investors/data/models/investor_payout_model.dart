class InvestorPayoutModel {
  final int id;
  final int? investorId;
  final String? investorFullName;
  final String employeeFullName;
  final double amount;
  final DateTime payoutDate;
  final String? payoutSource;
  final bool confirmed;

  InvestorPayoutModel({
    required this.id,
    this.investorId,
    this.investorFullName,
    required this.employeeFullName,
    required this.amount,
    required this.payoutDate,
    this.payoutSource,
    this.confirmed = false,
  });

  factory InvestorPayoutModel.fromJson(Map<String, dynamic> json) {
    final rawSource = json['payoutSource'];
    final source = switch (rawSource) {
      2 => 'investment',
      1 => 'income',
      _ => rawSource?.toString().toLowerCase(),
    };
    return InvestorPayoutModel(
      id: (json['id'] as num).toInt(),
      investorId: (json['investorId'] as num?)?.toInt(),
      investorFullName: json['investorFullName'] as String?,
      employeeFullName: json['employeeFullName'] as String? ?? '—',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      payoutDate:
          DateTime.tryParse(json['payoutDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      payoutSource: source,
      confirmed: json['confirmed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'investorId': investorId,
      'investorFullName': investorFullName,
      'employeeFullName': employeeFullName,
      'amount': amount,
      'payoutDate': payoutDate.toIso8601String(),
      'payoutSource': payoutSource,
      'confirmed': confirmed,
    };
  }
}

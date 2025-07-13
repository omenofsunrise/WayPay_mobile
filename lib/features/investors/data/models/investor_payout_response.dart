class InvestorPayoutResponse {
  final int id;
  final String? employeeFullName;
  final double amount;
  final DateTime payoutDate;

  InvestorPayoutResponse({
    required this.id,
    this.employeeFullName,
    required this.amount,
    required this.payoutDate,
  });

  factory InvestorPayoutResponse.fromJson(Map<String, dynamic> json) {
    return InvestorPayoutResponse(
      id: json['id'] as int,
      employeeFullName: json['employeeFullName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      payoutDate: DateTime.parse(json['payoutDate'] as String),
    );
  }
}

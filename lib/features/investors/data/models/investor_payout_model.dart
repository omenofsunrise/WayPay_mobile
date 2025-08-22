class InvestorPayoutModel {
  final int id;
  final String employeeFullName;
  final double amount;
  final DateTime payoutDate;

  InvestorPayoutModel({
    required this.id,
    required this.employeeFullName,
    required this.amount,
    required this.payoutDate,
  });

  factory InvestorPayoutModel.fromJson(Map<String, dynamic> json) {
    return InvestorPayoutModel(
      id: json['id'],
      employeeFullName: json['employeeFullName'],
      amount: (json['amount'] as num).toDouble(),
      payoutDate: DateTime.parse(json['payoutDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeFullName': employeeFullName,
      'amount': amount,
      'payoutDate': payoutDate.toIso8601String(),
    };
  }
}

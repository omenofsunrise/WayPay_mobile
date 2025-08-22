class PaymentModel {
  final int id;
  final int creditId;
  final double paymentAmount;
  final DateTime paymentDate;
  final String type;
  final bool accepted;
  final String clientFullName;
  final String investorNickname;
  final String employeeFullName;
  final double income;

  PaymentModel({
    required this.id,
    required this.creditId,
    required this.paymentAmount,
    required this.paymentDate,
    required this.type,
    required this.accepted,
    required this.clientFullName,
    required this.investorNickname,
    required this.employeeFullName,
    required this.income,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      creditId: json['creditId'] as int,
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      type: json['type'] as String,
      accepted: json['accepted'] as bool,
      clientFullName: json['clientFullName'] as String,
      investorNickname: json['investorNickname'] as String,
      employeeFullName: json['employeeFullName'] as String,
      income: (json['income'] as num).toDouble(),
    );
  }
}

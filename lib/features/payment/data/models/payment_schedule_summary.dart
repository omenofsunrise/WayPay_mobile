class PaymentScheduleSummary {
  const PaymentScheduleSummary({
    required this.title,
    required this.expectedIncome,
    required this.realIncome,
    required this.debt,
    required this.incomePercent,
    required this.debtPercent,
  });

  final String title;
  final double expectedIncome;
  final double realIncome;
  final double debt;
  final double incomePercent;
  final double debtPercent;

  factory PaymentScheduleSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return PaymentScheduleSummary(
      title: json['title']?.toString() ?? '',
      expectedIncome: parseDouble(json['expectedIncome']),
      realIncome: parseDouble(json['realIncome']),
      debt: parseDouble(json['debt']),
      incomePercent: parseDouble(json['incomePercent']),
      debtPercent: parseDouble(json['debtPercent']),
    );
  }
}

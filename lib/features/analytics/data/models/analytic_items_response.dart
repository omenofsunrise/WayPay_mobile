class AnalyticItemsResponse {
  final int investmentAmount;
  final int investmentAmountDiffrence;
  final int cash;
  final int cashDiffrence;
  final int latePayment;
  final int latePaymentDiffrence;
  final int activeCredits;
  final int activeCreditsDiffrence;
  final int totalCredits;
  final int sales;
  final int purchases;
  final int restAmount;
  final int restAmountDiffrence;

  AnalyticItemsResponse({
    required this.investmentAmount,
    required this.investmentAmountDiffrence,
    required this.cash,
    required this.cashDiffrence,
    required this.latePayment,
    required this.latePaymentDiffrence,
    required this.activeCredits,
    required this.activeCreditsDiffrence,
    required this.totalCredits,
    required this.sales,
    required this.purchases,
    required this.restAmount,
    required this.restAmountDiffrence,
  });

  factory AnalyticItemsResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticItemsResponse(
      investmentAmount: json['investmentAmount'] ?? 0,
      investmentAmountDiffrence: json['investmentAmountDiffrence'] ?? 0,
      cash: json['cash'] ?? 0,
      cashDiffrence: json['cashDiffrence'] ?? 0,
      latePayment: json['latePayment'] ?? 0,
      latePaymentDiffrence: json['latePaymentDiffrence'] ?? 0,
      activeCredits: json['activeCredits'] ?? 0,
      activeCreditsDiffrence: json['activeCreditsDiffrence'] ?? 0,
      totalCredits: json['totalCredits'] ?? 0,
      sales: json['sales'] ?? 0,
      purchases: json['purchases'] ?? 0,
      restAmount: json['restAmount'] ?? 0,
      restAmountDiffrence: json['restAmountDiffrence'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'investmentAmount': investmentAmount,
      'investmentAmountDiffrence': investmentAmountDiffrence,
      'cash': cash,
      'cashDiffrence': cashDiffrence,
      'latePayment': latePayment,
      'latePaymentDiffrence': latePaymentDiffrence,
      'activeCredits': activeCredits,
      'activeCreditsDiffrence': activeCreditsDiffrence,
      'totalCredits': totalCredits,
      'sales': sales,
      'purchases': purchases,
      'restAmount': restAmount,
      'restAmountDiffrence': restAmountDiffrence,
    };
  }
}

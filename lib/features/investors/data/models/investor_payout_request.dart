class InvestorPayoutRequest {
  final int investorId;
  final double amount;
  final String? payoutSource;

  InvestorPayoutRequest({
    required this.investorId,
    required this.amount,
    this.payoutSource,
  });

  Map<String, dynamic> toJson() => {
    'investorId': investorId,
    'amount': amount,
    if (payoutSource != null) 'payoutSource': payoutSource,
  };
}

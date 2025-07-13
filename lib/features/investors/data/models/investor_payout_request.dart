class InvestorPayoutRequest {
  final int investorId;
  final double amount;

  InvestorPayoutRequest({required this.investorId, required this.amount});

  Map<String, dynamic> toJson() => {'investorId': investorId, 'amount': amount};
}

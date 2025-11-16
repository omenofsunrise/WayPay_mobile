class CreateCreditApplicationRequest {
  const CreateCreditApplicationRequest({
    required this.productName,
    required this.productPrice,
    required this.termMonths,
    required this.districtId,
    this.firstPayment,
  });

  final String productName;
  final double productPrice;
  final int termMonths;
  final int districtId;
  final double? firstPayment;

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'productPrice': productPrice,
      'firstPayment': firstPayment,
      'termMonths': termMonths,
      'districtId': districtId,
    };
  }
}

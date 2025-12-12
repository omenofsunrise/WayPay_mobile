class BankCardRequest {
  final String? details;
  final String? phone;

  BankCardRequest({
    this.details,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'details': details,
      'phone': phone,
    };
  }
}

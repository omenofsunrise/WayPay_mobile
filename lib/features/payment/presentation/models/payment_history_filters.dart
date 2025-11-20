class PaymentHistoryFilters {
  const PaymentHistoryFilters({
    this.clientName,
    this.investor,
    this.dateFrom,
    this.dateTo,
    this.confirmed,
  });

  final String? clientName;
  final String? investor;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool? confirmed;

  bool get isEmpty =>
      (clientName == null || clientName!.isEmpty) &&
      (investor == null || investor!.isEmpty) &&
      dateFrom == null &&
      dateTo == null &&
      confirmed == null;

  PaymentHistoryFilters copyWith({
    String? clientName,
    String? investor,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? confirmed,
  }) {
    return PaymentHistoryFilters(
      clientName: clientName ?? this.clientName,
      investor: investor ?? this.investor,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}

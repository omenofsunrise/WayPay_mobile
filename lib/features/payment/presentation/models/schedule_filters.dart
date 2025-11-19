class ScheduleFilters {
  const ScheduleFilters({
    this.contractNumber,
    this.investor,
    this.clientFullName,
    this.dateFrom,
    this.dateTo,
  });

  final int? contractNumber;
  final String? investor;
  final String? clientFullName;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get isEmpty =>
      contractNumber == null &&
      (investor == null || investor!.isEmpty) &&
      (clientFullName == null || clientFullName!.isEmpty) &&
      dateFrom == null &&
      dateTo == null;

  ScheduleFilters copyWith({
    int? contractNumber,
    String? investor,
    String? clientFullName,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return ScheduleFilters(
      contractNumber: contractNumber ?? this.contractNumber,
      investor: investor ?? this.investor,
      clientFullName: clientFullName ?? this.clientFullName,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }

  String? get dateFromIso => dateFrom?.toIso8601String();
  String? get dateToIso => dateTo?.toIso8601String();
}

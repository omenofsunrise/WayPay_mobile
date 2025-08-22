class GetCreditsQuery {
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final String? sortDirection;
  final int? creditId;
  final int? investorId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? investorNickname;
  final String? clientFullname;
  final bool? isFavourite;
  final bool? isActive;
  final bool? debt;
  final double? rublesIncomeFrom;
  final double? rublesIncomeTo;
  final double? percentsIncomeFrom;
  final double? percentsIncomeTo;

  GetCreditsQuery({
    this.page,
    this.pageSize,
    this.sortBy,
    this.sortDirection,
    this.creditId,
    this.investorId,
    this.dateFrom,
    this.dateTo,
    this.investorNickname,
    this.clientFullname,
    this.isFavourite,
    this.isActive,
    this.debt,
    this.rublesIncomeFrom,
    this.rublesIncomeTo,
    this.percentsIncomeFrom,
    this.percentsIncomeTo,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (page != null) 'page': page,
      if (pageSize != null) 'pageSize': pageSize,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDirection != null) 'sortDirection': sortDirection,
      if (creditId != null) 'creditId': creditId,
      if (investorId != null) 'investorId': investorId,
      if (dateFrom != null) 'dateFrom': dateFrom!.toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo!.toIso8601String(),
      if (investorNickname != null) 'investorNickname': investorNickname,
      if (clientFullname != null) 'clientFullname': clientFullname,
      if (isFavourite != null) 'isFavourite': isFavourite,
      if (isActive != null) 'isActive': isActive,
      if (debt != null) 'debt': debt,
      if (rublesIncomeFrom != null) 'rublesIncomeFrom': rublesIncomeFrom,
      if (rublesIncomeTo != null) 'rublesIncomeTo': rublesIncomeTo,
      if (percentsIncomeFrom != null) 'percentsIncomeFrom': percentsIncomeFrom,
      if (percentsIncomeTo != null) 'percentsIncomeTo': percentsIncomeTo,
    };
  }

  GetCreditsQuery copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortDirection,
    int? creditId,
    int? investorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? investorNickname,
    String? clientFullname,
    bool? isFavourite,
    bool? isActive,
    bool? debt,
    double? rublesIncomeFrom,
    double? rublesIncomeTo,
    double? percentsIncomeFrom,
    double? percentsIncomeTo,
  }) {
    return GetCreditsQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      creditId: creditId ?? this.creditId,
      investorId: investorId ?? this.investorId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      investorNickname: investorNickname ?? this.investorNickname,
      clientFullname: clientFullname ?? this.clientFullname,
      isFavourite: isFavourite ?? this.isFavourite,
      isActive: isActive ?? this.isActive,
      debt: debt ?? this.debt,
      rublesIncomeFrom: rublesIncomeFrom ?? this.rublesIncomeFrom,
      rublesIncomeTo: rublesIncomeTo ?? this.rublesIncomeTo,
      percentsIncomeFrom: percentsIncomeFrom ?? this.percentsIncomeFrom,
      percentsIncomeTo: percentsIncomeTo ?? this.percentsIncomeTo,
    );
  }
}

class GetCreditsQuery {
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final String? sortDirection;
  final String? search;
  final int? creditId;
  final int? investorId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? investorNickname;
  final int? clientId;
  final String? clientFullname;
  final bool? isFavourite;
  final bool? isActive;
  final bool? debt;
  final double? rublesIncomeFrom;
  final double? rublesIncomeTo;
  final double? percentsIncomeFrom;
  final double? percentsIncomeTo;
  final int? creditTypeId;

  /// Номер или название договора — отдельный фильтр от search.
  final String? name;
  final String? clientAddress;

  /// Дата создания договора, не дата подписания.
  final DateTime? createdAt;
  final DateTime? createdTo;

  /// Источник инвестиций: пул.
  final int? investorPoolId;
  final int? objectTypeId;
  final bool? inDebt;
  final bool? terminated;
  final bool? myCredits;

  GetCreditsQuery({
    this.page,
    this.pageSize,
    this.sortBy,
    this.sortDirection,
    this.search,
    this.creditId,
    this.investorId,
    this.dateFrom,
    this.dateTo,
    this.investorNickname,
    this.clientId,
    this.clientFullname,
    this.isFavourite,
    this.isActive,
    this.debt,
    this.rublesIncomeFrom,
    this.rublesIncomeTo,
    this.percentsIncomeFrom,
    this.percentsIncomeTo,
    this.creditTypeId,
    this.name,
    this.clientAddress,
    this.createdAt,
    this.createdTo,
    this.investorPoolId,
    this.objectTypeId,
    this.inDebt,
    this.terminated,
    this.myCredits,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (page != null) 'page': page,
      if (pageSize != null) 'pageSize': pageSize,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDirection != null) 'sortDirection': sortDirection,
      if (search != null) 'search': search,
      if (creditId != null) 'creditId': creditId,
      if (investorId != null) 'investorId': investorId,
      if (dateFrom != null) 'dateFrom': dateFrom!.toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo!.toIso8601String(),
      if (investorNickname != null) 'investorNickname': investorNickname,
      if (clientId != null) 'clientId': clientId,
      if (clientFullname != null) 'clientFullname': clientFullname,
      if (isFavourite != null) 'isFavourite': isFavourite,
      if (isActive != null) 'isActive': isActive,
      if (debt != null) 'debt': debt,
      if (rublesIncomeFrom != null) 'rublesIncomeFrom': rublesIncomeFrom,
      if (rublesIncomeTo != null) 'rublesIncomeTo': rublesIncomeTo,
      if (percentsIncomeFrom != null) 'percentsIncomeFrom': percentsIncomeFrom,
      if (percentsIncomeTo != null) 'percentsIncomeTo': percentsIncomeTo,
      if (creditTypeId != null) 'creditTypeId': creditTypeId,
      if (name != null) 'name': name,
      if (clientAddress != null) 'clientAddress': clientAddress,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (createdTo != null) 'createdTo': createdTo!.toIso8601String(),
      if (investorPoolId != null) 'investorPoolId': investorPoolId,
      if (objectTypeId != null) 'objectTypeId': objectTypeId,
      if (inDebt != null) 'inDebt': inDebt,
      if (terminated != null) 'terminated': terminated,
      if (myCredits != null) 'myCredits': myCredits,
    };
  }

  GetCreditsQuery copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortDirection,
    String? search,
    int? creditId,
    int? investorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? investorNickname,
    int? clientId,
    String? clientFullname,
    bool? isFavourite,
    bool? isActive,
    bool? debt,
    double? rublesIncomeFrom,
    double? rublesIncomeTo,
    double? percentsIncomeFrom,
    double? percentsIncomeTo,
    int? creditTypeId,
    String? name,
    String? clientAddress,
    DateTime? createdAt,
    DateTime? createdTo,
    int? investorPoolId,
    int? objectTypeId,
    bool? inDebt,
    bool? terminated,
    bool? myCredits,
  }) {
    return GetCreditsQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      search: search ?? this.search,
      creditId: creditId ?? this.creditId,
      investorId: investorId ?? this.investorId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      investorNickname: investorNickname ?? this.investorNickname,
      clientId: clientId ?? this.clientId,
      clientFullname: clientFullname ?? this.clientFullname,
      isFavourite: isFavourite ?? this.isFavourite,
      isActive: isActive ?? this.isActive,
      debt: debt ?? this.debt,
      rublesIncomeFrom: rublesIncomeFrom ?? this.rublesIncomeFrom,
      rublesIncomeTo: rublesIncomeTo ?? this.rublesIncomeTo,
      percentsIncomeFrom: percentsIncomeFrom ?? this.percentsIncomeFrom,
      percentsIncomeTo: percentsIncomeTo ?? this.percentsIncomeTo,
      creditTypeId: creditTypeId ?? this.creditTypeId,
      name: name ?? this.name,
      clientAddress: clientAddress ?? this.clientAddress,
      createdAt: createdAt ?? this.createdAt,
      createdTo: createdTo ?? this.createdTo,
      investorPoolId: investorPoolId ?? this.investorPoolId,
      objectTypeId: objectTypeId ?? this.objectTypeId,
      inDebt: inDebt ?? this.inDebt,
      terminated: terminated ?? this.terminated,
      myCredits: myCredits ?? this.myCredits,
    );
  }
}

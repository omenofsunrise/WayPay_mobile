class GetScheduleQuery {
  final int page;
  final int pageSize;
  final String sortDirection;
  final String sortBy;
  final String? clientName;
  final String? investorNickname;
  final int? creditId;
  final String? dateFrom;
  final String? dateTo;

  GetScheduleQuery({
    this.page = 1,
    this.pageSize = 20,
    this.sortDirection = 'asc',
    this.sortBy = 'date',
    this.clientName,
    this.investorNickname,
    this.creditId,
    this.dateFrom,
    this.dateTo,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      'page': page,
      'pageSize': pageSize,
      'sortDirection': sortDirection,
      'sortBy': sortBy,
      if (clientName != null && clientName!.isNotEmpty) 'clientName': clientName,
      if (investorNickname != null && investorNickname!.isNotEmpty) 'investorNickname': investorNickname,
      if (creditId != null) 'creditId': creditId,
      if (dateFrom != null && dateFrom!.isNotEmpty) 'datefrom': dateFrom,
      if (dateTo != null && dateTo!.isNotEmpty) 'dateTo': dateTo,
    };
  }
}

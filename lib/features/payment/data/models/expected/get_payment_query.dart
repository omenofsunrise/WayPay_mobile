class GetPaymentsQuery {
  final int page;
  final int pageSize;
  final String sortBy;
  final String sortDirection;
  final String? clientFullname;
  final String? investorNickname;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool? confirmed;

  GetPaymentsQuery({
    this.page = 1,
    this.pageSize = 20,
    this.sortBy = 'date',
    this.sortDirection = 'desc',
    this.clientFullname,
    this.investorNickname,
    this.dateFrom,
    this.dateTo,
    this.confirmed,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (clientFullname != null && clientFullname!.isNotEmpty) {
      params['clientFullname'] = clientFullname;
    }

    if (investorNickname != null && investorNickname!.isNotEmpty) {
      params['investorNickname'] = investorNickname;
    }

    if (dateFrom != null) {
      params['dateFrom'] = dateFrom!.toIso8601String();
    }

    if (dateTo != null) {
      params['dateTo'] = dateTo!.toIso8601String();
    }

    if (confirmed != null) {
      params['confirmed'] = confirmed;
    }

    return params;
  }
}

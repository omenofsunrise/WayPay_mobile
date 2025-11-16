class GetClientsQuery {
  final String? fullName;
  final String? phone;
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final String? sortDirection;

  GetClientsQuery({
    this.fullName,
    this.phone,
    this.page,
    this.pageSize,
    this.sortBy,
    this.sortDirection,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (fullName != null) 'FullName': fullName,
      if (phone != null) 'Phone': phone,
      if (page != null) 'Page': page,
      if (pageSize != null) 'PageSize': pageSize,
      if (sortBy != null) 'SortBy': sortBy,
      if (sortDirection != null) 'SortDirection': sortDirection,
    };
  }
}

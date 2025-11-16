class GetCreditApplicationsQuery {
  const GetCreditApplicationsQuery({
    this.minPrice,
    this.maxPrice,
    this.minTerm,
    this.maxTerm,
    this.regionId,
    this.districtId,
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.onlyMine,
  });

  final double? minPrice;
  final double? maxPrice;
  final int? minTerm;
  final int? maxTerm;
  final int? regionId;
  final int? districtId;
  final int page;
  final int pageSize;
  final String? search;
  final bool? onlyMine;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (minTerm != null) params['minTerm'] = minTerm;
    if (maxTerm != null) params['maxTerm'] = maxTerm;
    if (regionId != null) params['regionId'] = regionId;
    if (districtId != null) params['districtId'] = districtId;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (onlyMine != null) params['onlyMine'] = onlyMine;

    return params;
  }
}

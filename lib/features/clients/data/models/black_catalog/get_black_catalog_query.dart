class GetBlackCatalogQuery {
  const GetBlackCatalogQuery({
    this.fullName,
    this.doc,
    this.phone,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? fullName;
  final String? doc;
  final String? phone;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParams() {
    return {
      'Page': page,
      'PageSize': pageSize,
      if (fullName != null && fullName!.isNotEmpty) 'FullName': fullName,
      if (doc != null && doc!.isNotEmpty) 'Doc': doc,
      if (phone != null && phone!.isNotEmpty) 'Phone': phone,
    };
  }
}

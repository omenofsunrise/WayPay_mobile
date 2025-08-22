class GetQueueQuery {
  final int page;
  final int pageSize;
  final String sortBy;
  final bool descending;
  final String? name;

  GetQueueQuery({
    this.page = 1,
    this.pageSize = 20,
    this.sortBy = 'positionInQueue',
    this.descending = false,
    this.name,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'sortBy': sortBy,
      'descending': descending.toString(),
    };

    if (name != null && name!.isNotEmpty) {
      params['name'] = name;
    }

    return params;
  }
}

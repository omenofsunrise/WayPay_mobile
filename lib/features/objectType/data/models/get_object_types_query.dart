class GetObjectTypesQuery {
  final int? page;
  final int? pageSize;
  final String? entityType;

  GetObjectTypesQuery({this.page = 1, this.pageSize = 20, this.entityType});

  Map<String, dynamic> toQueryParams() {
    return {
      if (page != null) 'page': page,
      if (pageSize != null) 'pageSize': pageSize,
      if (entityType != null) 'entityType': entityType,
    };
  }

  GetObjectTypesQuery copyWith({int? page, int? pageSize, String? entityType}) {
    return GetObjectTypesQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      entityType: entityType ?? this.entityType,
    );
  }
}

class CheckObjectTypeExistsQuery {
  final String? name;
  final String? entityType;

  CheckObjectTypeExistsQuery({this.name, this.entityType});

  Map<String, dynamic> toQueryParams() {
    return {
      if (name != null) 'name': name,
      if (entityType != null) 'entityType': entityType,
    };
  }
}

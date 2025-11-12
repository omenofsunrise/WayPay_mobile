class ObjectTypeModel {
  final int id;
  final String name;
  final String entityType;

  ObjectTypeModel({
    required this.id,
    required this.name,
    required this.entityType,
  });

  factory ObjectTypeModel.fromJson(Map<String, dynamic> json) {
    return ObjectTypeModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      entityType: json['entityType'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'entityType': entityType};
  }

  ObjectTypeModel copyWith({int? id, String? name, String? entityType}) {
    return ObjectTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      entityType: entityType ?? this.entityType,
    );
  }
}

class ObjectTypeResponseModel {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<ObjectTypeModel> items;

  ObjectTypeResponseModel({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  factory ObjectTypeResponseModel.fromJson(Map<String, dynamic> json) {
    return ObjectTypeResponseModel(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => ObjectTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CreateObjectTypeRequest {
  final String name;
  final String entityType;

  CreateObjectTypeRequest({required this.name, required this.entityType});

  Map<String, dynamic> toJson() {
    return {'name': name, 'entityType': entityType};
  }
}

class UpdateObjectTypeRequest {
  final String name;

  UpdateObjectTypeRequest({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

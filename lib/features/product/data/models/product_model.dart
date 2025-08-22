class ProductModel {
  final int id;
  final String name;

  ProductModel({required this.id, required this.name});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }

  ProductModel copyWith({int? id, String? name}) {
    return ProductModel(id: id ?? this.id, name: name ?? this.name);
  }
}

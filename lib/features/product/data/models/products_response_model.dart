import 'package:waypay/features/product/data/models/product_model.dart';

class ProductsResponseModel {
  final List<ProductModel> products;
  final int totalCount;
  final int pageSize;
  final int page;

  ProductsResponseModel({
    required this.products,
    required this.totalCount,
    required this.pageSize,
    required this.page,
  });

  factory ProductsResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductsResponseModel(
      products: (json['items'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 20,
      page: json['page'] as int? ?? 1,
    );
  }
}

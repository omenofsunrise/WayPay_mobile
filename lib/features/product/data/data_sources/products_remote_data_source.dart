import 'package:waypay/features/product/data/models/product_model.dart';
import 'package:waypay/features/product/data/models/products_response_model.dart';

abstract class ProductsRemoteDataSource {
  Future<ProductsResponseModel> getProducts({
    int page,
    int pageSize,
    String sortDirection,
    String sortBy,
    String? name,
  });
  Future<void> createProduct({required String name});
  Future<ProductModel> getProductById(int id);
  Future<void> updateProduct({required int id, required String name});
  Future<void> deleteProduct(int id);
}

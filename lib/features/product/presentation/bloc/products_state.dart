part of 'products_bloc.dart';

abstract class ProductsState {}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<ProductModel> products;
  final int totalCount;
  final int perPage;
  final int currentPage;

  ProductsLoaded({
    required this.products,
    required this.totalCount,
    required this.perPage,
    required this.currentPage,
  });

  int get totalPages => (totalCount / perPage).ceil();
}

class ProductsError extends ProductsState {
  final String message;

  ProductsError(this.message);
}

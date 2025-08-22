part of 'products_bloc.dart';

abstract class ProductsEvent {}

class LoadProductsEvent extends ProductsEvent {
  final bool refresh;
  final int? page;
  final String? sortBy;
  final String? sortDirection;

  LoadProductsEvent({
    this.refresh = false,
    this.page,
    this.sortBy,
    this.sortDirection,
  });
}

class SearchProductsEvent extends ProductsEvent {
  final String query;

  SearchProductsEvent(this.query);
}

class ResetSearchProductsEvent extends ProductsEvent {}

class UpdateProductNameEvent extends ProductsEvent {
  final int productId;
  final String newName;

  UpdateProductNameEvent({required this.productId, required this.newName});
}

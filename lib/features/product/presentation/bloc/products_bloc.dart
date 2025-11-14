import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/product/data/data_sources/products_remote_data_source.dart';
import 'package:waypay_mobile/features/product/data/models/product_model.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final _productDataSource = getIt<ProductsRemoteDataSource>();
  final _tokenStorage = getIt<TokenStorage>();

  String? _searchQuery;

  ProductsBloc() : super(ProductsInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<SearchProductsEvent>(_onSearchProducts);
    on<ResetSearchProductsEvent>(_onResetSearchProducts);
    on<UpdateProductNameEvent>(_onUpdateProductName);
  }

  Future<void> _onLoadProducts(
    LoadProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(ProductsError('Токен авторизации отсутствует.'));
        return;
      }

      final response = await _productDataSource.getProducts(
        page: event.page ?? 1,
        sortBy: event.sortBy ?? 'name',
        sortDirection: event.sortDirection ?? 'asc',
        name: _searchQuery,
      );

      emit(
        ProductsLoaded(
          products: response.products,
          totalCount: response.totalCount,
          perPage: response.pageSize,
          currentPage: response.page,
        ),
      );
    } catch (e) {
      emit(ProductsError('Ошибка: $e'));
    }
  }

  Future<void> _onSearchProducts(
    SearchProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    _searchQuery = event.query;
    add(LoadProductsEvent(refresh: true, page: 1));
  }

  Future<void> _onResetSearchProducts(
    ResetSearchProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    _searchQuery = null;
    add(LoadProductsEvent(refresh: true, page: 1));
  }

  Future<void> _onUpdateProductName(
    UpdateProductNameEvent event,
    Emitter<ProductsState> emit,
  ) async {
    if (state is ProductsLoaded) {
      final currentState = state as ProductsLoaded;

      final updatedProducts = currentState.products.map((product) {
        if (product.id == event.productId) {
          return product.copyWith(name: event.newName);
        }
        return product;
      }).toList();

      emit(
        ProductsLoaded(
          products: updatedProducts,
          totalCount: currentState.totalCount,
          perPage: currentState.perPage,
          currentPage: currentState.currentPage,
        ),
      );
    }
  }
}

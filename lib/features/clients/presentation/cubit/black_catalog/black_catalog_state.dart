part of 'black_catalog_cubit.dart';

abstract class BlackCatalogState {}

class BlackCatalogInitial extends BlackCatalogState {}

class BlackCatalogLoading extends BlackCatalogState {}

class BlackCatalogLoaded extends BlackCatalogState {
  BlackCatalogLoaded(this.clients);

  final List<BlackCatalogClientModel> clients;
}

class BlackCatalogError extends BlackCatalogState {
  BlackCatalogError(this.message);

  final String message;
}

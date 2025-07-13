part of 'clients_bloc.dart';

abstract class ClientsEvent {}

class LoadClients extends ClientsEvent {
  final bool refresh;
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final String? sortDirection;
  final String? search;

  LoadClients({this.refresh = false, this.page, this.pageSize = 10, this.sortBy, this.sortDirection, this.search});
}

class SearchClients extends ClientsEvent {
  final String query;
  final int? pageSize;

  SearchClients(this.query, {this.pageSize});
}

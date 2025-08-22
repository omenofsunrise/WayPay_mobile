part of 'blacklist_bloc.dart';

abstract class BlacklistEvent {}

class LoadBlacklistedClients extends BlacklistEvent {
  final bool refresh;
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final String? sortDirection;
  final String? search;

  LoadBlacklistedClients({
    this.refresh = false,
    this.page,
    this.pageSize = 10,
    this.sortBy,
    this.sortDirection,
    this.search,
  });
}

class SearchBlacklistedClients extends BlacklistEvent {
  final String query;
  final int? pageSize;

  SearchBlacklistedClients(this.query, {this.pageSize});
}

class AddClientToBlacklist extends BlacklistEvent {
  final ClientModel client;

  AddClientToBlacklist(this.client);
}

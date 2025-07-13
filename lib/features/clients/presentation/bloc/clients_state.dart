part of 'clients_bloc.dart';

abstract class ClientsState {}

class ClientsInitial extends ClientsState {}

class ClientsLoading extends ClientsState {}

class ClientsLoaded extends ClientsState {
  final List<ClientModel> clients;
  final bool hasMoreData;
  final int currentPage;
  final int totalPages;

  ClientsLoaded({
    required this.clients,
    required this.hasMoreData,
    required this.currentPage,
    required this.totalPages,
  });

  ClientsLoaded copyWith({List<ClientModel>? clients, bool? hasMoreData, int? currentPage, int? totalPages}) {
    return ClientsLoaded(
      clients: clients ?? this.clients,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class ClientsError extends ClientsState {
  final String message;

  ClientsError(this.message);
}

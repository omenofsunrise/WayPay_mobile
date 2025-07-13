part of 'blacklist_bloc.dart';

abstract class BlacklistState {}

class BlacklistInitial extends BlacklistState {}

class BlacklistLoading extends BlacklistState {}

class BlacklistLoaded extends BlacklistState {
  final List<ClientModel> clients;
  final bool hasMoreData;
  final int currentPage;
  final int totalPages;

  BlacklistLoaded({
    required this.clients,
    required this.hasMoreData,
    required this.currentPage,
    required this.totalPages,
  });

  BlacklistLoaded copyWith({List<ClientModel>? clients, bool? hasMoreData, int? currentPage, int? totalPages}) {
    return BlacklistLoaded(
      clients: clients ?? this.clients,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class BlacklistError extends BlacklistState {
  final String message;

  BlacklistError(this.message);
}

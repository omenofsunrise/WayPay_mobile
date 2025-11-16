import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/blacklist/blacklist_remote_data_sources.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/get_clients_query.dart';

part 'blacklist_event.dart';
part 'blacklist_state.dart';

class BlacklistBloc extends Bloc<BlacklistEvent, BlacklistState> {
  final BlacklistRemoteDataSources _blacklistDataSource =
      getIt<BlacklistRemoteDataSources>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  List<ClientModel> _blacklistedClients = [];
  int _currentPage = 1;
  bool _hasMore = true;

  BlacklistBloc() : super(BlacklistInitial()) {
    on<LoadBlacklistedClients>(_onLoadBlacklistedClients);
    on<SearchBlacklistedClients>(_onSearchBlacklistedClients);
    on<AddClientToBlacklist>(_onAddClientToBlacklist);
  }

  Future<void> _onLoadBlacklistedClients(
    LoadBlacklistedClients event,
    Emitter<BlacklistState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = event.page ?? 1;
      _hasMore = true;
      _blacklistedClients.clear();
      emit(BlacklistLoading());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.page ?? _currentPage;
    }

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(BlacklistError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final phone = _extractPhone(event.search);
      final query = GetClientsQuery(
        fullName: phone == null ? event.search : null,
        phone: phone,
        page: _currentPage,
        pageSize: event.pageSize ?? 20,
        sortBy: event.sortBy,
        sortDirection: event.sortDirection,
      );

      final response = await _blacklistDataSource.getClientsBlacklist(query);

      if (event.refresh) {
        _blacklistedClients = response.clients;
      } else {
        _blacklistedClients.addAll(response.clients);
      }

      final totalPages = (response.totalCount / (event.pageSize ?? 20)).ceil();
      _hasMore = _currentPage < totalPages;

      emit(
        BlacklistLoaded(
          clients: List.from(_blacklistedClients),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      emit(BlacklistError('Ошибка при загрузке чёрного списка: $e'));
    }
  }

  Future<void> _onSearchBlacklistedClients(
    SearchBlacklistedClients event,
    Emitter<BlacklistState> emit,
  ) async {
    emit(BlacklistLoading());

    try {
      final phone = _extractPhone(event.query);
      final query = GetClientsQuery(
        fullName: phone == null ? event.query : null,
        phone: phone,
        page: 1,
        pageSize: event.pageSize ?? 10,
      );

      final response = await _blacklistDataSource.getClientsBlacklist(query);
      final totalPages = (response.totalCount / (event.pageSize ?? 10)).ceil();

      emit(
        BlacklistLoaded(
          clients: response.clients,
          hasMoreData: totalPages > 1,
          currentPage: 1,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      emit(BlacklistError('Ошибка при поиске в чёрном списке: $e'));
    }
  }

  Future<void> _onAddClientToBlacklist(
    AddClientToBlacklist event,
    Emitter<BlacklistState> emit,
  ) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(BlacklistError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      await _blacklistDataSource.toBlackList(event.client.id);

      add(LoadBlacklistedClients(refresh: true, page: 1, pageSize: 10));
    } catch (e) {
      emit(BlacklistError('Не удалось добавить клиента в чёрный список: $e'));
    }
  }

  String? _extractPhone(String? value) {
    if (value == null) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 11) {
      return digits;
    }
    return null;
  }
}

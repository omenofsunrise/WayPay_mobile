import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/clients/client_model.dart';
import 'package:waypay/features/clients/data/models/clients/create_clients_requests.dart';
import 'package:waypay/features/clients/data/models/clients/get_clients_query.dart';

part 'clients_event.dart';
part 'clients_state.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final ClientRemoteDataSource _clientDataSource =
      getIt<ClientRemoteDataSource>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  List<ClientModel> _clients = [];
  int _currentPage = 1;
  bool _hasMore = true;

  ClientsBloc() : super(ClientsInitial()) {
    on<LoadClients>(_onLoadClients);
    on<SearchClients>(_onSearchClients);
    on<CreateClient>(_onCreateClient);
  }

  Future<void> _onLoadClients(
    LoadClients event,
    Emitter<ClientsState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = event.page ?? 1;
      _hasMore = true;
      _clients.clear();
      emit(ClientsLoading());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.page ?? _currentPage;
    }

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(ClientsError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final query = GetClientsQuery(
        fullName: event.search,
        page: _currentPage,
        pageSize: event.pageSize ?? 20,
        sortBy: event.sortBy,
        sortDirection: event.sortDirection,
      );

      final response = await _clientDataSource.getClients(query);

      if (event.refresh) {
        _clients = response.clients;
      } else {
        _clients.addAll(response.clients);
      }
      final totalPages = (response.totalCount / (event.pageSize ?? 20)).ceil();

      final hasMore = _currentPage < totalPages;
      _hasMore = hasMore;

      emit(
        ClientsLoaded(
          clients: List.from(_clients),
          hasMoreData: hasMore,
          currentPage: _currentPage,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      emit(ClientsError('Ошибка при загрузке клиентов: $e'));
    }
  }

  Future<void> _onSearchClients(
    SearchClients event,
    Emitter<ClientsState> emit,
  ) async {
    emit(ClientsLoading());

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(ClientsError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }
      final query = GetClientsQuery(
        fullName: event.query,
        page: 1,
        pageSize: event.pageSize ?? 10,
      );

      final response = await _clientDataSource.getClients(query);

      final totalPages = (response.totalCount / (event.pageSize ?? 10)).ceil();

      emit(
        ClientsLoaded(
          clients: response.clients,
          hasMoreData: totalPages > 1,
          currentPage: response.page,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      emit(ClientsError('Ошибка при поиске клиентов: $e'));
    }
  }

  Future<void> _onCreateClient(
    CreateClient event,
    Emitter<ClientsState> emit,
  ) async {
    final currentState = state;
    List<ClientModel> currentClients = [];
    bool hasMoreData = true;
    int currentPage = 1;
    int totalPages = 1;

    if (currentState is ClientsLoaded) {
      currentClients = currentState.clients;
      hasMoreData = currentState.hasMoreData;
      currentPage = currentState.currentPage;
      totalPages = currentState.totalPages;
    }

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(ClientsError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      await _clientDataSource.createClient(event.request);

      emit(ClientCreateSuccess());

      add(LoadClients(refresh: true, page: 1, pageSize: 10));
    } catch (e) {
      final errorMessage = 'Ошибка при создании клиента: $e';
      final errorCode = e.toString().contains('409') ? 409 : null;
      emit(
        ClientsLoaded(
          clients: currentClients,
          hasMoreData: hasMoreData,
          currentPage: currentPage,
          totalPages: totalPages,
          errorMessage: errorMessage,
          errorCode: errorCode,
        ),
      );
    }
  }
}

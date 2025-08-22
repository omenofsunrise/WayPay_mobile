import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/queue/get_queue_query_model.dart';
import 'package:waypay/features/clients/data/data_sources/queue/queue_remote_data_source.dart';
import 'package:waypay/features/clients/data/models/queue/queue_model.dart';
import 'package:waypay/features/clients/data/models/queue/queue_request_model.dart';

part 'queue_event.dart';
part 'queue_state.dart';

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final QueueRemoteDataSource _queueDataSource = getIt<QueueRemoteDataSource>();
  final ClientRemoteDataSource _clientDataSource = getIt<ClientRemoteDataSource>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  List<QueueItemModel> _queue = [];
  int _currentPage = 1;
  bool _hasMore = true;

  QueueBloc() : super(QueueInitial()) {
    on<LoadQueue>(_onLoadQueue);
    on<SearchQueue>(_onSearchQueue);
    on<AddQueueItem>(_onAddQueueItem);
    on<DeleteQueueItem>(_onDeleteQueueItem);
    on<CloseQueueItem>(_onCloseQueueItem);
  }
  Future<void> _onLoadQueue(LoadQueue event, Emitter<QueueState> emit) async {
    if (event.refresh) {
      _currentPage = event.page ?? 1;
      _hasMore = true;
      _queue.clear();
      emit(QueueLoading());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.page ?? _currentPage;
    }

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(QueueError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final query = GetQueueQuery(
        page: _currentPage,
        pageSize: event.pageSize ?? 20,
        sortBy: event.sortBy ?? 'positionInQueue',
        descending: event.descending,
        name: event.search,
      );

      final response = await _queueDataSource.getQueue(query);

      for (final item in response.items) {
        try {
          final client = await _clientDataSource.getClientById(item.clientId);
          item.client = client;
        } catch (e) {
          emit(QueueError('Ошибка загрузки клиента с ID ${item.clientId}: $e'));
        }
      }

      if (event.refresh) {
        _queue = response.items;
      } else {
        _queue.addAll(response.items);
      }

      final totalPages = response.totalPages;
      _hasMore = _currentPage < totalPages;

      emit(
        QueueLoaded(queue: List.from(_queue), hasMoreData: _hasMore, currentPage: _currentPage, totalPages: totalPages),
      );
    } catch (e) {
      emit(QueueError('Ошибка при загрузке очереди: $e'));
    }
  }

  Future<void> _onSearchQueue(SearchQueue event, Emitter<QueueState> emit) async {
    emit(QueueLoading());

    try {
      final query = GetQueueQuery(name: event.query, page: 1, pageSize: event.pageSize ?? 20);

      final response = await _queueDataSource.getQueue(query);

      for (final item in response.items) {
        try {
          final client = await _clientDataSource.getClientById(item.clientId);
          item.client = client;
        } catch (e) {
          emit(QueueError('Ошибка загрузки клиента для clientId ${item.clientId}: $e'));
        }
      }

      emit(
        QueueLoaded(
          queue: response.items,
          hasMoreData: response.totalPages > 1,
          currentPage: response.page,
          totalPages: response.totalPages,
        ),
      );
    } catch (e) {
      emit(QueueError('Ошибка при поиске в очереди: $e'));
    }
  }

  Future<void> _onAddQueueItem(AddQueueItem event, Emitter<QueueState> emit) async {
    emit(QueueLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(QueueError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      await _queueDataSource.addQueueItem(event.request);

      add(LoadQueue(refresh: true));

      emit(QueueItemAdded());
    } catch (e) {
      emit(QueueError('Ошибка при добавлении в очередь: $e'));
    }
  }

  Future<void> _onDeleteQueueItem(DeleteQueueItem event, Emitter<QueueState> emit) async {
    emit(QueueLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(QueueError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      await _queueDataSource.deleteQueueById(event.id);

      add(LoadQueue(refresh: true));
      emit(QueueItemDeleted());
    } catch (e) {
      emit(QueueError('Ошибка при удалении из очереди: $e'));
    }
  }

  Future<void> _onCloseQueueItem(CloseQueueItem event, Emitter<QueueState> emit) async {
    emit(QueueLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(QueueError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      await _queueDataSource.closeQueueById(event.id);

      add(LoadQueue(refresh: true));
      emit(QueueItemClosed());
    } catch (e) {
      emit(QueueError('Ошибка при закрытии очереди: $e'));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';

part 'investor_pool_event.dart';
part 'investor_pool_state.dart';

class InvestorPoolBloc extends Bloc<InvestorPoolEvent, InvestorPoolState> {
  InvestorPoolBloc()
    : _dataSource = getIt<InvestorsRemoteDataSource>(),
      super(InvestorPoolInitial()) {
    on<LoadInvestorPool>(_onLoadPools);
    on<SearchInvestorPool>(_onSearch);
    on<ResetInvestorPool>(_onReset);
  }

  final InvestorsRemoteDataSource _dataSource;
  String? _query;
  List<InvestorPoolModel> _items = [];
  int _currentPage = 1;
  bool _hasMore = true;

  Future<void> _onLoadPools(
    LoadInvestorPool event,
    Emitter<InvestorPoolState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = 1;
      _items.clear();
      _hasMore = true;
      emit(InvestorPoolLoading());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.page ?? _currentPage;
    }

    try {
      final isSearching = _query?.trim().isNotEmpty == true;
      final response = await _dataSource.getInvestorPools(
        page: _currentPage,
        pageSize: isSearching ? 100 : event.pageSize,
        search: _query,
      );
      final loadedItems = isSearching
          ? response.items
                .where(
                  (pool) => pool.name.toLowerCase().contains(
                    _query!.trim().toLowerCase(),
                  ),
                )
                .toList()
          : response.items;
      if (event.refresh) {
        _items = loadedItems;
      } else {
        _items.addAll(loadedItems);
      }
      _hasMore = !isSearching && _currentPage < response.totalPages;
      emit(
        InvestorPoolLoaded(
          items: List.from(_items),
          hasMore: _hasMore,
          currentPage: _currentPage,
        ),
      );
    } catch (e) {
      emit(InvestorPoolError(e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchInvestorPool event,
    Emitter<InvestorPoolState> emit,
  ) async {
    _query = event.query.isEmpty ? null : event.query;
    add(LoadInvestorPool(refresh: true));
  }

  Future<void> _onReset(
    ResetInvestorPool event,
    Emitter<InvestorPoolState> emit,
  ) async {
    _query = null;
    add(LoadInvestorPool(refresh: true));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';

part 'investors_event.dart';
part 'investors_state.dart';

class InvestorsBloc extends Bloc<InvestorsEvent, InvestorsState> {
  final _investorDataSource = getIt<InvestorsRemoteDataSource>();
  final _tokenStorage = getIt<TokenStorage>();

  String? _searchQuery;
  List<InvestorsModel> _investors = [];
  int _currentPage = 1;
  bool _hasMore = true;

  InvestorsBloc() : super(InvestorsInitial()) {
    on<LoadInvestorsEvent>(_onLoadInvestors);
    on<SearchInvestorsEvent>(_onSearchInvestors);
    on<ResetSearchInvestorsEvent>(_onResetSearchInvestors);
    on<ToggleInvestorBlockStatusEvent>(_onToggleInvestorBlockStatus);
  }

  Future<void> _onLoadInvestors(
    LoadInvestorsEvent event,
    Emitter<InvestorsState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = event.page ?? 1;
      _hasMore = true;
      _investors.clear();
      emit(InvestorsLoading());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.page ?? _currentPage;
    }

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        emit(InvestorsError('Токен авторизации отсутствует.'));
        return;
      }

      final response = await _investorDataSource.getInvestors(
        page: _currentPage,
        pageSize: event.pageSize ?? 10,
        search: _searchQuery,
      );

      if (event.refresh) {
        _investors = response.investors;
      } else {
        _investors.addAll(response.investors);
      }

      final totalPages = (response.totalCount / response.pageSize).ceil();
      _hasMore = _currentPage < totalPages;

      emit(
        InvestorsLoaded(
          investors: List.from(_investors),
          hasMoreData: _hasMore,
          totalCount: response.totalCount,
          perPage: response.pageSize,
          currentPage: _currentPage,
        ),
      );
    } catch (e) {
      emit(InvestorsError('Ошибка: $e'));
    }
  }

  Future<void> _onSearchInvestors(
    SearchInvestorsEvent event,
    Emitter<InvestorsState> emit,
  ) async {
    _searchQuery = event.query;
    add(LoadInvestorsEvent(refresh: true, page: 1));
  }

  Future<void> _onResetSearchInvestors(
    ResetSearchInvestorsEvent event,
    Emitter<InvestorsState> emit,
  ) async {
    _searchQuery = null;
    add(LoadInvestorsEvent(refresh: true, page: 1));
  }

  Future<void> _onToggleInvestorBlockStatus(
    ToggleInvestorBlockStatusEvent event,
    Emitter<InvestorsState> emit,
  ) async {
    if (state is InvestorsLoaded) {
      final currentState = state as InvestorsLoaded;

      final updatedInvestors = currentState.investors.map((inv) {
        if (inv.id == event.investorId) {
          return inv.copyWith(isBlocked: !inv.isBlocked);
        }
        return inv;
      }).toList();

      emit(
        InvestorsLoaded(
          investors: updatedInvestors,
          hasMoreData: currentState.hasMoreData,
          totalCount: currentState.totalCount,
          perPage: currentState.perPage,
          currentPage: currentState.currentPage,
        ),
      );
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/data/models/investors_model.dart';

part 'investors_event.dart';
part 'investors_state.dart';

class InvestorsBloc extends Bloc<InvestorsEvent, InvestorsState> {
  final _investorDataSource = getIt<InvestorsRemoteDataSource>();
  final _tokenStorage = getIt<TokenStorage>();

  String? _searchQuery;

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
    emit(InvestorsLoading());

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        emit(InvestorsError('Токен авторизации отсутствует.'));
        return;
      }

      final response = await _investorDataSource.getInvestors(
        page: event.page ?? 1,
        pageSize: 10,
        search: _searchQuery,
      );

      emit(
        InvestorsLoaded(
          investors: response.investors,
          hasMoreData: response.investors.isNotEmpty,
          totalCount: response.totalCount,
          perPage: response.pageSize,
          currentPage: response.page,
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

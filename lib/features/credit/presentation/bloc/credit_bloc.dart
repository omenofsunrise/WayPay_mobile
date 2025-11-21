import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'credit_event.dart';
import 'credit_state.dart';

class CreditBloc extends Bloc<CreditEvent, CreditState> {
  final CreditRemoteDataSource _dataSource = getIt<CreditRemoteDataSource>();

  List<CreditModel> _credits = [];
  int _currentPage = 1;
  bool _hasMore = true;

  GetCreditsQuery _lastQuery = GetCreditsQuery();
  GetCreditsQuery get lastQuery => _lastQuery;

  CreditBloc() : super(CreditInitial()) {
    on<LoadCreditsEvent>(_onLoadCredits);
    on<SearchCreditsEvent>(_onSearchCredits);
    on<ToggleFavouriteEvent>(_onToggleFavourite);
    on<DeleteCreditEvent>(_onDeleteCredit);
    on<LoadInvestorCreditsEvent>(_onLoadInvestorCredits);
    on<CreateCreditEvent>(_onCreateCredit);
  }

  Future<void> _onCreateCredit(
    CreateCreditEvent event,
    Emitter<CreditState> emit,
  ) async {
    emit(CreditCreating());

    try {
      final createdCredit = await _dataSource.createCredit(event.request);

      _credits.insert(0, createdCredit);

      emit(CreditCreated(createdCredit: createdCredit));

      final prevState = state is CreditLoaded ? state as CreditLoaded : null;
      emit(
        CreditLoaded(
          credits: List.from(_credits),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: prevState?.totalPages ?? 1,
          totalCount: (prevState?.totalCount ?? 0) + 1,
        ),
      );
    } catch (e) {
      emit(CreditCreationError('Ошибка создания договора: $e'));

      if (state is CreditLoaded) {
        emit(state);
      } else {
        emit(CreditError('Не удалось создать договор'));
      }
    }
  }

  Future<void> _onLoadCredits(
    LoadCreditsEvent event,
    Emitter<CreditState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = event.query.page ?? 1;
      _hasMore = true;
      _credits.clear();
      emit(CreditLoading());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.query.page ?? _currentPage;
    }

    try {
      final query = event.query.copyWith(page: _currentPage);
      _lastQuery = query;
      final response = await _dataSource.getCredits(query);

      if (event.refresh) {
        _credits = response.items;
      } else {
        _credits.addAll(response.items);
      }

      final totalPages = response.totalPages;
      _hasMore = _currentPage < totalPages;

      emit(
        CreditLoaded(
          credits: List.from(_credits),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: totalPages,
          totalCount: response.totalCount,
        ),
      );
    } catch (e) {
      emit(CreditError('Ошибка при загрузке договоров: $e'));
    }
  }

  Future<void> _onSearchCredits(
    SearchCreditsEvent event,
    Emitter<CreditState> emit,
  ) async {
    emit(CreditLoading());
    try {
      final query = GetCreditsQuery(
        page: 1,
        pageSize: event.pageSize ?? 20,
        clientFullname: event.query,
      );

      _lastQuery = query;

      final response = await _dataSource.getCredits(query);

      emit(
        CreditLoaded(
          credits: response.items,
          hasMoreData: response.totalPages > 1,
          currentPage: response.page,
          totalPages: response.totalPages,
          totalCount: response.totalCount,
        ),
      );
    } catch (e) {
      emit(CreditError('Ошибка при поиске договоров: $e'));
    }
  }

  Future<void> _onToggleFavourite(
    ToggleFavouriteEvent event,
    Emitter<CreditState> emit,
  ) async {
    try {
      final index = _credits.indexWhere((c) => c.id == event.creditId);
      if (index == -1) return;

      final credit = _credits[index];
      final updated = credit.copyWith(isFavourite: !(credit.isFavourite));
      _credits[index] = updated;
      final prevState = state is CreditLoaded ? state as CreditLoaded : null;
      emit(
        CreditLoaded(
          credits: List.from(_credits),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: (state is CreditLoaded)
              ? (state as CreditLoaded).totalPages
              : 1,
          totalCount: prevState?.totalCount ?? 0,
        ),
      );

      await _dataSource.toggleFavourite(event.creditId);
    } catch (e) {
      emit(CreditError('Ошибка при обновлении избранного: $e'));
    }
  }

  Future<void> _onDeleteCredit(
    DeleteCreditEvent event,
    Emitter<CreditState> emit,
  ) async {
    debugPrint('🔴 Обработка DeleteCreditEvent: ${event.creditId}');
    try {
      await _dataSource.deleteCreditById(event.creditId);

      _credits.removeWhere((c) => c.id == event.creditId);
      debugPrint('✅ Договор удалён локально: ${event.creditId}');
      final prevState = state is CreditLoaded ? state as CreditLoaded : null;

      emit(
        CreditLoaded(
          credits: List.from(_credits),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: prevState?.totalPages ?? 1,
          totalCount: (prevState?.totalCount ?? 0) - 1,
        ),
      );
    } catch (e) {
      debugPrint('❌ Ошибка при удалении договора: $e');
      emit(CreditError('Ошибка при удалении договора: $e'));
    }
  }

  Future<void> _onLoadInvestorCredits(
    LoadInvestorCreditsEvent event,
    Emitter<CreditState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = event.query.page ?? 1;
      _hasMore = true;
      _credits.clear();
      emit(CreditLoading());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.query.page ?? _currentPage;
    }

    try {
      final query = event.query.copyWith(page: _currentPage);
      _lastQuery = query;

      final response = await _dataSource.getCreditsByInvestorId(
        event.investorId,
        query,
      );

      if (event.refresh) {
        _credits = response.items;
      } else {
        _credits.addAll(response.items);
      }

      _hasMore = _currentPage < response.totalPages;

      emit(
        CreditLoaded(
          credits: List.from(_credits),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: response.totalPages,
          totalCount: response.totalCount,
        ),
      );
    } catch (e) {
      emit(CreditError('Ошибка при загрузке кредитов инвестора: $e'));
    }
  }
}

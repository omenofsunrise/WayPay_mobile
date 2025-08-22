import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay/features/payment/data/models/schedule/get_schedule_query.dart';
import 'package:waypay/features/payment/data/models/schedule/schedule_model.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRemoteDataSources _scheduleDataSource = getIt<ScheduleRemoteDataSources>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  List<ScheduleModel> _schedules = [];
  int _currentPage = 1;
  bool _hasMore = true;

  ScheduleBloc() : super(ScheduleInitial()) {
    on<LoadSchedule>(_onLoadSchedule);
    on<SearchSchedule>(_onSearchSchedule);
  }

  Future<void> _onLoadSchedule(LoadSchedule event, Emitter<ScheduleState> emit) async {
    if (event.refresh) {
      _currentPage = event.page ?? 1;
      _hasMore = true;
      _schedules.clear();
      emit(ScheduleInitial());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.page ?? _currentPage;
    }

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(ScheduleError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final query = GetScheduleQuery(
        page: _currentPage,
        pageSize: event.pageSize ?? 10,
        sortBy: event.sortBy ?? 'date',
        sortDirection: event.sortDirection ?? 'asc',
        clientName: event.search ?? event.clientName,
        investorNickname: event.investorNickname,
        creditId: event.creditId,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      );

      final response = await _scheduleDataSource.getSchedule(query);

      if (event.refresh) {
        _schedules = response.items;
      } else {
        _schedules.addAll(response.items);
      }

      final totalPages = response.totalPages;
      _hasMore = _currentPage < totalPages;

      emit(
        ScheduleLoaded(
          schedules: List.from(_schedules),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      emit(ScheduleError('Ошибка при загрузке расписания: $e'));
    }
  }

  Future<void> _onSearchSchedule(SearchSchedule event, Emitter<ScheduleState> emit) async {
    emit(ScheduleInitial());

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(ScheduleError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final query = GetScheduleQuery(page: 1, pageSize: event.pageSize ?? 10, clientName: event.query);

      final response = await _scheduleDataSource.getSchedule(query);

      _schedules = response.items;
      _currentPage = 1;
      _hasMore = response.totalPages > 1;

      emit(
        ScheduleLoaded(
          schedules: List.from(_schedules),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: response.totalPages,
        ),
      );
    } catch (e) {
      emit(ScheduleError('Ошибка при поиске расписания: $e'));
    }
  }
}

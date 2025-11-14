import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/get_payment_query.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRemoteDataSources _paymentDataSource =
      getIt<PaymentRemoteDataSources>();
  final TokenStorage _tokenStorage = getIt<TokenStorage>();

  List<PaymentItemModel> _payments = [];
  int _currentPage = 1;
  bool _hasMore = true;

  PaymentBloc() : super(PaymentInitial()) {
    on<LoadPayment>(_onLoadPayment);
    on<SearchPayment>(_onSearchPayment);
    on<ConfirmPayment>(_onConfirmPayment);
    on<DeletePayment>(_onDeletePayment);
  }

  Future<void> _onLoadPayment(
    LoadPayment event,
    Emitter<PaymentState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = event.page ?? 1;
      _hasMore = true;
      _payments.clear();
      emit(PaymentInitial());
    } else if (!_hasMore) {
      return;
    } else {
      _currentPage = event.page ?? _currentPage;
    }

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(PaymentError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      final query = GetPaymentsQuery(
        page: _currentPage,
        pageSize: event.pageSize ?? 20,
        sortBy: event.sortBy ?? 'date',
        sortDirection: event.descending ? 'desc' : 'asc',
        clientFullname: event.search,
        investorNickname: event.investorNickname,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      );

      final response = await _paymentDataSource.getPayment(query);

      if (event.refresh) {
        _payments = response.items;
      } else {
        _payments.addAll(response.items);
      }

      final totalPages = response.totalPages;
      _hasMore = _currentPage < totalPages;

      emit(
        PaymentLoaded(
          payment: List.from(_payments),
          hasMoreData: _hasMore,
          currentPage: _currentPage,
          totalPages: totalPages,
          totalCount: response.totalCount,
          totalPayments: response.totalPayments,
          totalIncome: response.totalIncome,
        ),
      );
    } catch (e) {
      emit(PaymentError('Ошибка при загрузке платежей: $e'));
    }
  }

  Future<void> _onSearchPayment(
    SearchPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentInitial());

    try {
      final query = GetPaymentsQuery(
        page: 1,
        pageSize: event.pageSize ?? 20,
        clientFullname: event.query,
      );

      final response = await _paymentDataSource.getPayment(query);

      emit(
        PaymentLoaded(
          payment: response.items,
          hasMoreData: response.totalPages > 1,
          currentPage: response.page,
          totalPages: response.totalPages,
          totalCount: response.totalCount,
          totalPayments: response.totalPayments,
          totalIncome: response.totalIncome,
        ),
      );
    } catch (e) {
      emit(PaymentError('Ошибка при поиске платежей: $e'));
    }
  }

  Future<void> _onConfirmPayment(
    ConfirmPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(PaymentError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      await _paymentDataSource.confirmPayment(event.id);

      add(LoadPayment(refresh: true, page: 1, pageSize: 10));
    } catch (e) {
      emit(PaymentConfirmFailure('Ошибка при подтверждении платежа: $e'));
    }
  }

  Future<void> _onDeletePayment(
    DeletePayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(PaymentError('Сессия истекла. Пожалуйста, войдите снова.'));
        return;
      }

      await _paymentDataSource.deletePayment(event.id);

      add(LoadPayment(refresh: true, page: 1, pageSize: 10));
    } catch (e) {
      emit(PaymentDeleteFailure('Ошибка при удалении платежа: $e'));
    }
  }
}

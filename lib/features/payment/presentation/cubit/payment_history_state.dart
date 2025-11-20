part of 'payment_history_cubit.dart';

sealed class PaymentHistoryState {}

final class PaymentHistoryInitial extends PaymentHistoryState {}

final class PaymentHistoryLoading extends PaymentHistoryState {}

final class PaymentHistoryLoaded extends PaymentHistoryState {
  PaymentHistoryLoaded(this.payments);

  final List<PaymentItemModel> payments;
}

final class PaymentHistoryError extends PaymentHistoryState {
  PaymentHistoryError(this.message);

  final String message;
}

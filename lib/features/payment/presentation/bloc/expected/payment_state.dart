part of 'payment_bloc.dart';

@immutable
sealed class PaymentState {}

final class PaymentInitial extends PaymentState {}

class PaymentLoaded extends PaymentState {
  final List<PaymentItemModel> payment;
  final bool hasMoreData;
  final int currentPage;
  final int totalCount;
  final int totalPages;
  final double totalPayments;
  final int totalIncome;

  PaymentLoaded({
    required this.payment,
    required this.hasMoreData,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.totalPayments = 0,
    this.totalIncome = 0,
  });

  PaymentLoaded copyWith({
    List<PaymentItemModel>? payment,
    bool? hasMoreData,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    double? totalPayments,
    int? totalIncome,
  }) {
    return PaymentLoaded(
      payment: payment ?? this.payment,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      totalPayments: totalPayments ?? this.totalPayments,
      totalIncome: totalIncome ?? this.totalIncome,
    );
  }
}

class PaymentError extends PaymentState {
  final String message;

  PaymentError(this.message);
}

class PaymentConfirmFailure extends PaymentState {
  final String message;

  PaymentConfirmFailure(this.message);
}

class PaymentDeleteFailure extends PaymentState {
  final String message;

  PaymentDeleteFailure(this.message);
}

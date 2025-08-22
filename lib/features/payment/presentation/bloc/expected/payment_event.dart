part of 'payment_bloc.dart';

@immutable
sealed class PaymentEvent {}

class LoadPayment extends PaymentEvent {
  final bool refresh;
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final bool descending;
  final String? search;
  final String? investorNickname;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  LoadPayment({
    this.refresh = false,
    this.page,
    this.pageSize,
    this.sortBy = 'date',
    this.descending = false,
    this.search,
    this.investorNickname,
    this.dateFrom,
    this.dateTo,
  });
}

class SearchPayment extends PaymentEvent {
  final String query;
  final int? pageSize;
  final String? clientFullname;
  final String? investorNickname;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  SearchPayment(this.query, {this.pageSize, this.clientFullname, this.investorNickname, this.dateFrom, this.dateTo});
}

class ConfirmPayment extends PaymentEvent {
  final int id;

  ConfirmPayment(this.id);
}

class DeletePayment extends PaymentEvent {
  final int id;

  DeletePayment(this.id);
}

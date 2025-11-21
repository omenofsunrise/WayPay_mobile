import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';

abstract class CreditEvent {}

class LoadCreditsEvent extends CreditEvent {
  final bool refresh;
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final bool descending;
  final String? search;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool? isActive;
  final bool? isFavourite;
  final bool? debt;
  final GetCreditsQuery query;

  LoadCreditsEvent({
    this.refresh = false,
    this.page,
    this.pageSize,
    this.sortBy,
    this.descending = true,
    this.search,
    this.dateFrom,
    this.dateTo,
    this.isActive,
    this.isFavourite,
    this.debt,
    required this.query,
  });
}

class SearchCreditsEvent extends CreditEvent {
  final String query;
  final int? pageSize;

  SearchCreditsEvent(this.query, {this.pageSize});
}

class ToggleFavouriteEvent extends CreditEvent {
  final int creditId;

  ToggleFavouriteEvent({required this.creditId});
}

class DeleteCreditEvent extends CreditEvent {
  final int creditId;

  DeleteCreditEvent(this.creditId);
}

class LoadInvestorCreditsEvent extends CreditEvent {
  final bool refresh;
  final int investorId;
  final GetCreditsQuery query;

  LoadInvestorCreditsEvent({
    required this.investorId,
    required this.query,
    required this.refresh,
  });
}

class CreateCreditEvent extends CreditEvent {
  final CreateCreditRequest request;

  CreateCreditEvent({required this.request});
}

class CreateCreditSuccessEvent extends CreditEvent {
  final CreditModel createdCredit;

  CreateCreditSuccessEvent({required this.createdCredit});
}

class LoadSchedulePreviewEvent extends CreditEvent {
  final double totalAmount;
  final double firstPayment;
  final int termMonths;
  final int paymentDay;
  final bool currentMonthStart;
  final bool nextMonthStart;

  LoadSchedulePreviewEvent({
    required this.totalAmount,
    required this.firstPayment,
    required this.termMonths,
    required this.paymentDay,
    required this.currentMonthStart,
    required this.nextMonthStart,
  });
}

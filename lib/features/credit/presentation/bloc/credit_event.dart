import 'package:waypay/features/credit/data/models/get_query_credits.dart';

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

  LoadInvestorCreditsEvent({required this.investorId, required this.query, required this.refresh});
}

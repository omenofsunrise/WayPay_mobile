part of 'investors_bloc.dart';

abstract class InvestorsEvent {}

class LoadInvestorsEvent extends InvestorsEvent {
  final bool refresh;
  final int? page;

  LoadInvestorsEvent({this.refresh = false, this.page});
}

class SearchInvestorsEvent extends InvestorsEvent {
  final String query;

  SearchInvestorsEvent(this.query);
}

class ResetSearchInvestorsEvent extends InvestorsEvent {}

class ToggleInvestorBlockStatusEvent extends InvestorsEvent {
  final int investorId;

  ToggleInvestorBlockStatusEvent(this.investorId);
}

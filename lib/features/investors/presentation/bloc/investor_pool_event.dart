part of 'investor_pool_bloc.dart';

abstract class InvestorPoolEvent {}

class LoadInvestorPool extends InvestorPoolEvent {
  LoadInvestorPool({this.refresh = false, this.page, this.pageSize = 10});
  final bool refresh;
  final int? page;
  final int pageSize;
}

class SearchInvestorPool extends InvestorPoolEvent {
  SearchInvestorPool(this.query);
  final String query;
}

class ResetInvestorPool extends InvestorPoolEvent {}

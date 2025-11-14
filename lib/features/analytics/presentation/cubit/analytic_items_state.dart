import 'package:equatable/equatable.dart';
import 'package:waypay_mobile/features/analytics/data/models/analytic_items_response.dart';

abstract class AnalyticItemsState extends Equatable {
  const AnalyticItemsState();

  @override
  List<Object?> get props => [];
}

class AnalyticItemsInitial extends AnalyticItemsState {}

class AnalyticItemsLoading extends AnalyticItemsState {}

class AnalyticItemsLoaded extends AnalyticItemsState {
  final AnalyticItemsResponse data;
  const AnalyticItemsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AnalyticItemsError extends AnalyticItemsState {
  final String message;
  const AnalyticItemsError(this.message);

  @override
  List<Object?> get props => [message];
}

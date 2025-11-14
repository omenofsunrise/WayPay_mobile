import 'package:equatable/equatable.dart';
import 'package:waypay_mobile/features/analytics/data/models/graph_data.dart';

abstract class InvestmentDynamicState extends Equatable {
  const InvestmentDynamicState();

  @override
  List<Object?> get props => [];
}

class InvestmentDynamicInitial extends InvestmentDynamicState {}

class InvestmentDynamicLoading extends InvestmentDynamicState {}

class InvestmentDynamicLoaded extends InvestmentDynamicState {
  final GraphData data;
  const InvestmentDynamicLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class InvestmentDynamicError extends InvestmentDynamicState {
  final String message;
  const InvestmentDynamicError(this.message);

  @override
  List<Object?> get props => [message];
}

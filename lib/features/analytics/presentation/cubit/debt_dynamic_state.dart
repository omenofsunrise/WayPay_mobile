import 'package:equatable/equatable.dart';
import 'package:waypay/features/analytics/data/models/debt_dynamic_response.dart';

abstract class DebtDynamicState extends Equatable {
  const DebtDynamicState();

  @override
  List<Object?> get props => [];
}

class DebtDynamicInitial extends DebtDynamicState {}

class DebtDynamicLoading extends DebtDynamicState {}

class DebtDynamicLoaded extends DebtDynamicState {
  final DebtDynamicResponse data;
  const DebtDynamicLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class DebtDynamicError extends DebtDynamicState {
  final String message;
  const DebtDynamicError(this.message);

  @override
  List<Object?> get props => [message];
}

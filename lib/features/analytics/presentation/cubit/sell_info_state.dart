import 'package:equatable/equatable.dart';
import 'package:waypay_mobile/features/analytics/data/models/sell_info_response.dart';

abstract class SellInfoState extends Equatable {
  const SellInfoState();

  @override
  List<Object?> get props => [];
}

class SellInfoInitial extends SellInfoState {}

class SellInfoLoading extends SellInfoState {}

class SellInfoLoaded extends SellInfoState {
  final SellInfoResponse data;
  const SellInfoLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class SellInfoError extends SellInfoState {
  final String message;
  const SellInfoError(this.message);

  @override
  List<Object?> get props => [message];
}

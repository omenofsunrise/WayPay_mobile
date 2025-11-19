part of 'payment_schedule_cubit.dart';

abstract class PaymentScheduleState {}

class PaymentScheduleInitial extends PaymentScheduleState {}

class PaymentScheduleLoading extends PaymentScheduleState {}

class PaymentScheduleLoaded extends PaymentScheduleState {
  PaymentScheduleLoaded(this.summaries);

  final List<PaymentScheduleSummary> summaries;
}

class PaymentScheduleError extends PaymentScheduleState {
  PaymentScheduleError(this.message);

  final String message;
}

class PaymentScheduleNoAccess extends PaymentScheduleState {}

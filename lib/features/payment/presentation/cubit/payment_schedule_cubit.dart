import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/payment/data/models/payment_schedule_summary.dart';

part 'payment_schedule_state.dart';

class PaymentScheduleCubit extends Cubit<PaymentScheduleState> {
  PaymentScheduleCubit({AnalyticRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? getIt<AnalyticRemoteDataSource>(),
      super(PaymentScheduleInitial());

  final AnalyticRemoteDataSource _remoteDataSource;

  Future<void> load({int? year}) async {
    if (!UserStorage().hasPermissionSync([Permission.viewAnalytic])) {
      emit(PaymentScheduleNoAccess());
      return;
    }
    emit(PaymentScheduleLoading());
    try {
      final schedules = await _remoteDataSource.getPaymentSchedules(year: year);
      emit(PaymentScheduleLoaded(schedules));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        emit(PaymentScheduleNoAccess());
        return;
      }
      emit(
        PaymentScheduleError(
          'Ошибка получения аналитики платежей: ${e.response?.statusCode ?? e.message}',
        ),
      );
    } catch (e) {
      emit(PaymentScheduleError(e.toString()));
    }
  }
}

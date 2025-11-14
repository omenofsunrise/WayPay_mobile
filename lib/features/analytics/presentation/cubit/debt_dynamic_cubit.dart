import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'debt_dynamic_state.dart';

class DebtDynamicCubit extends Cubit<DebtDynamicState> {
  DebtDynamicCubit() : super(DebtDynamicInitial());

  Future<void> loadDebtDynamic({
    String? predefinedPeriod,
    String? start,
    String? end,
  }) async {
    emit(DebtDynamicLoading());
    try {
      final data = await getIt<AnalyticRemoteDataSource>().getDebtDynamic(
        predefinedPeriod: predefinedPeriod,
        start: start,
        end: end,
      );
      emit(DebtDynamicLoaded(data));
    } catch (e) {
      emit(DebtDynamicError(e.toString()));
    }
  }
}

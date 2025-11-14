import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'package:waypay_mobile/features/analytics/data/models/graph_data.dart';
import 'investment_dynamic_state.dart';

class InvestmentDynamicCubit extends Cubit<InvestmentDynamicState> {
  InvestmentDynamicCubit() : super(InvestmentDynamicInitial());

  Future<void> loadInvestmentDynamic({
    String? predefinedPeriod,
    String? start,
    String? end,
  }) async {
    emit(InvestmentDynamicLoading());
    try {
      final GraphData data = await getIt<AnalyticRemoteDataSource>()
          .getInvestmentAmountDynamic(
            predefinedPeriod: predefinedPeriod,
            start: start,
            end: end,
          );
      emit(InvestmentDynamicLoaded(data));
    } catch (e) {
      emit(InvestmentDynamicError(e.toString()));
    }
  }
}

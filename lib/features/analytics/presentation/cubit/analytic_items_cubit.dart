import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'package:waypay_mobile/features/analytics/data/models/analytic_items_response.dart';
import 'analytic_items_state.dart';

class AnalyticItemsCubit extends Cubit<AnalyticItemsState> {
  AnalyticItemsCubit() : super(AnalyticItemsInitial());

  Future<void> loadAnalyticItems({
    String? predefinedPeriod,
    String? start,
    String? end,
  }) async {
    emit(AnalyticItemsLoading());
    try {
      final AnalyticItemsResponse data = await getIt<AnalyticRemoteDataSource>()
          .getAnalyticItems(
            predefinedPeriod: predefinedPeriod,
            start: start,
            end: end,
          );
      emit(AnalyticItemsLoaded(data));
    } catch (e) {
      emit(AnalyticItemsError(e.toString()));
    }
  }
}

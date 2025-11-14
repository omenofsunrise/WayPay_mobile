import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/analytics/data/data_sources/analytic_remote_data_source.dart';
import 'package:waypay_mobile/features/analytics/data/models/sell_info_response.dart';
import 'sell_info_state.dart';

class SellInfoCubit extends Cubit<SellInfoState> {
  SellInfoCubit() : super(SellInfoInitial());

  Future<void> loadSellInfo({
    String? predefinedPeriod,
    String? start,
    String? end,
  }) async {
    emit(SellInfoLoading());
    try {
      final SellInfoResponse data = await getIt<AnalyticRemoteDataSource>()
          .getSellInfo(
            predefinedPeriod: predefinedPeriod,
            start: start,
            end: end,
          );
      emit(SellInfoLoaded(data));
    } catch (e) {
      emit(SellInfoError(e.toString()));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/get_schedule_query.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';

part 'schedule_preview_state.dart';

class SchedulePreviewCubit extends Cubit<SchedulePreviewState> {
  SchedulePreviewCubit({ScheduleRemoteDataSources? scheduleRemoteDataSources})
    : _scheduleRemoteDataSources =
            scheduleRemoteDataSources ?? getIt<ScheduleRemoteDataSources>(),
      super(SchedulePreviewInitial());

  final ScheduleRemoteDataSources _scheduleRemoteDataSources;

  Future<void> load({int limit = 2}) async {
    emit(SchedulePreviewLoading());
    try {
      final response = await _scheduleRemoteDataSources.getSchedule(
        GetScheduleQuery(
          page: 1,
          pageSize: limit,
          sortBy: 'date',
          sortDirection: 'asc',
        ),
      );

      emit(SchedulePreviewLoaded(response.items));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(
        SchedulePreviewError(
          'Ошибка загрузки ожидаемых платежей: $message',
        ),
      );
    }
  }
}

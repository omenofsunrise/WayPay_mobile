import 'package:waypay_mobile/features/payment/data/models/schedule/get_schedule_query.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';

abstract class ScheduleRemoteDataSources {
  Future<ScheduleResponseModel> getSchedule(GetScheduleQuery query);
  Future<void> putSchedule(int id);
}

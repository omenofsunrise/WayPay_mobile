import 'package:waypay/features/clients/data/models/queue/get_queue_query_model.dart';
import 'package:waypay/features/clients/data/models/queue/queue_model.dart';
import 'package:waypay/features/clients/data/models/queue/queue_request_model.dart';

abstract class QueueRemoteDataSource {
  Future<QueueResponseModel> getQueue(GetQueueQuery query);
  Future<void> addQueueItem(QueueRequestModel request);
  Future<QueueItemModel> getQueueById(int id);
  Future<void> closeQueueById(int id);
  Future<void> deleteQueueById(int id);
  Future<void> updateQueueById(int id, QueueRequestModel request);
}

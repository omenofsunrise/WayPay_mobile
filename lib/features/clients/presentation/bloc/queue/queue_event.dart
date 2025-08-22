part of 'queue_bloc.dart';

abstract class QueueEvent {}

class LoadQueue extends QueueEvent {
  final bool refresh;
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final bool descending;
  final String? search;

  LoadQueue({
    this.refresh = false,
    this.page,
    this.pageSize,
    this.sortBy = 'positionInQueue',
    this.descending = false,
    this.search,
  });
}

class SearchQueue extends QueueEvent {
  final String query;
  final int? pageSize;

  SearchQueue(this.query, {this.pageSize});
}

class AddQueueItem extends QueueEvent {
  final QueueRequestModel request;

  AddQueueItem(this.request);
}

class DeleteQueueItem extends QueueEvent {
  final int id;

  DeleteQueueItem(this.id);
}

class CloseQueueItem extends QueueEvent {
  final int id;

  CloseQueueItem(this.id);
}

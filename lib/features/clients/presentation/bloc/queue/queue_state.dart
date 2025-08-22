part of 'queue_bloc.dart';

abstract class QueueState {}

class QueueInitial extends QueueState {}

class QueueLoading extends QueueState {}

class QueueLoaded extends QueueState {
  final List<QueueItemModel> queue;
  final bool hasMoreData;
  final int currentPage;
  final int totalPages;

  QueueLoaded({required this.queue, required this.hasMoreData, required this.currentPage, required this.totalPages});

  QueueLoaded copyWith({List<QueueItemModel>? queue, bool? hasMoreData, int? currentPage, int? totalPages}) {
    return QueueLoaded(
      queue: queue ?? this.queue,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class QueueError extends QueueState {
  final String message;

  QueueError(this.message);
}

class QueueItemAdded extends QueueState {}

class QueueItemDeleted extends QueueState {}

class QueueItemClosed extends QueueState {}

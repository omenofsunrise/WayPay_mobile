part of 'notifications_cubit.dart';

abstract class NotificationsState {
  const NotificationsState();

  int get totalCount => 0;
  int get unreadCount => 0;
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  NotificationsLoaded(
    this.page, {
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final NotificationPage page;
  final bool hasMore;
  final bool isLoadingMore;

  List<NotificationModel> get items => page.items;
  bool get isEmpty => items.isEmpty;

  NotificationsLoaded copyWith({
    NotificationPage? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => NotificationsLoaded(
    page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  int get totalCount => page.totalCount;

  @override
  int get unreadCount => items.where((item) => !item.isRead).length;
}

class NotificationsError extends NotificationsState {
  NotificationsError(this.message);

  final String message;
}

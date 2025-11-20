import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/features/notifications/data/data_source/notifications_data_source.dart';
import 'package:waypay_mobile/features/notifications/data/models/notification_page.dart';
import 'package:waypay_mobile/features/notifications/data/models/notification_model.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._dataSource) : super(const NotificationsInitial());

  final NotificationsDataSource _dataSource;

  static const int _defaultPageSize = 8;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _markUnreadOnFetch = false;

  Future<void> load({bool refresh = false, bool markAsRead = false}) async {
    if (!refresh) emit(const NotificationsLoading());
    try {
      _currentPage = 1;
      _isLoadingMore = false;
      _markUnreadOnFetch = markAsRead;
      final page = await _dataSource.fetchNotifications(
        page: _currentPage,
        pageSize: _defaultPageSize,
      );
      final sorted = page.items.toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      final normalizedItems = await _processUnreadItems(
        sorted,
        markAsRead: markAsRead,
      );
      final normalizedPageSize = _resolvePageSize(page.pageSize);
      final normalizedPage = NotificationPage(
        page: _currentPage,
        pageSize: normalizedPageSize,
        totalCount: _resolveTotalCount(
          previous: 0,
          next: page.totalCount,
          fallback: sorted.length,
        ),
        totalPages: _resolveTotalPages(previous: 0, next: page.totalPages),
        items: normalizedItems,
      );
      final hasMore = _determineHasMore(
        page: normalizedPage,
        fetchedItemsCount: page.items.length,
        accumulatedItemsCount: normalizedPage.items.length,
        currentPage: _currentPage,
      );
      emit(
        NotificationsLoaded(
          normalizedPage,
          hasMore: hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    if (_isLoadingMore) return;
    if (!current.hasMore) return;

    _isLoadingMore = true;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPageIndex = _currentPage + 1;
      final next = await _dataSource.fetchNotifications(
        page: nextPageIndex,
        pageSize: _defaultPageSize,
      );
      final fetchedItems = await _processUnreadItems(
        next.items,
        markAsRead: _markUnreadOnFetch,
      );
      final effectivePageIndex = fetchedItems.isNotEmpty
          ? nextPageIndex
          : _currentPage;
      final combined = [...current.items, ...fetchedItems]
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      final normalizedPageSize = _resolvePageSize(next.pageSize);
      final mergedPage = NotificationPage(
        page: effectivePageIndex,
        pageSize: normalizedPageSize,
        totalCount: _resolveTotalCount(
          previous: current.totalCount,
          next: next.totalCount,
          fallback: combined.length,
        ),
        totalPages: _resolveTotalPages(
          previous: current.page.totalPages,
          next: next.totalPages,
        ),
        items: combined,
      );
      final hasMore = _determineHasMore(
        page: mergedPage,
        fetchedItemsCount: fetchedItems.length,
        accumulatedItemsCount: combined.length,
        currentPage: effectivePageIndex,
      );
      _currentPage = effectivePageIndex;
      emit(
        NotificationsLoaded(mergedPage, hasMore: hasMore, isLoadingMore: false),
      );
    } catch (e) {
      // откат isLoadingMore, но оставим текущие данные
      emit(current.copyWith(isLoadingMore: false));
    } finally {
      _isLoadingMore = false;
    }
  }

  void removeNotification(int id) {
    final current = state;
    if (current is! NotificationsLoaded) return;

    final filtered = current.items.where((e) => e.id != id).toList();
    final updatedTotal = (current.totalCount - 1).clamp(0, current.totalCount);
    emit(
      NotificationsLoaded(
        current.page.copyWith(items: filtered, totalCount: updatedTotal),
        hasMore: current.hasMore,
        isLoadingMore: current.isLoadingMore,
      ),
    );
  }

  Future<void> markAsRead(int id) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    final index = current.items.indexWhere((element) => element.id == id);
    if (index == -1) return;
    final target = current.items[index];
    if (target.isRead) return;

    try {
      await _dataSource.markAsRead(id);
      final updatedItems = [...current.items];
      updatedItems[index] = target.copyWith(isRead: true);
      final updatedPage = current.page.copyWith(items: updatedItems);
      emit(current.copyWith(page: updatedPage));
    } catch (e) {
      // ignore failure but log
      // ignore: avoid_print
      print('⚠️ Не удалось отметить уведомление $id как прочитанное: $e');
    }
  }

  Future<List<NotificationModel>> _processUnreadItems(
    List<NotificationModel> source, {
    required bool markAsRead,
  }) async {
    if (!markAsRead || source.isEmpty) return source;
    final updated = List<NotificationModel>.from(source);
    final unread = <NotificationModel>[];
    for (final notification in source) {
      if (!notification.isRead) unread.add(notification);
    }
    if (unread.isEmpty) return updated;

    for (final notification in unread) {
      try {
        await _dataSource.markAsRead(notification.id);
        final idx = updated.indexWhere((item) => item.id == notification.id);
        if (idx != -1) {
          updated[idx] = updated[idx].copyWith(isRead: true);
        }
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ Не удалось отметить уведомление ${notification.id}: $e');
      }
    }
    return updated;
  }

  int _resolvePageSize(int value) => value > 0 ? value : _defaultPageSize;

  int _resolveTotalCount({
    required int previous,
    required int next,
    required int fallback,
  }) {
    if (next > 0) return next;
    if (previous > 0) return previous;
    return fallback;
  }

  int _resolveTotalPages({required int previous, required int next}) {
    if (next > 0) return next;
    if (previous > 0) return previous;
    return 0;
  }

  bool _determineHasMore({
    required NotificationPage page,
    required int fetchedItemsCount,
    required int accumulatedItemsCount,
    required int currentPage,
  }) {
    if (page.totalPages > 0 && currentPage < page.totalPages) {
      return true;
    }
    if (page.totalCount > 0 && accumulatedItemsCount < page.totalCount) {
      return true;
    }
    if (fetchedItemsCount == 0) {
      return false;
    }
    return fetchedItemsCount >= page.pageSize;
  }
}

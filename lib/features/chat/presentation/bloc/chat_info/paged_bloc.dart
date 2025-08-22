import 'package:flutter_bloc/flutter_bloc.dart';

part 'paged_event.dart';
part 'paged_state.dart';

typedef FetchPage<T> = Future<List<T>> Function({required int skip, required int take});

class PagedBloc<T> extends Bloc<PagedEvent, PagedState<T>> {
  final FetchPage<T> fetchPage;
  final int pageSize;

  int _skip = 0;
  bool _hasMore = true;
  final List<T> _items = [];

  PagedBloc({required this.fetchPage, this.pageSize = 20}) : super(PagedInitial<T>()) {
    on<LoadPage<T>>(_onLoadPage);
    on<RefreshPage<T>>(_onRefreshPage);
  }

  Future<void> _onLoadPage(LoadPage<T> event, Emitter<PagedState<T>> emit) async {
    if (!_hasMore && !event.refresh) return;

    if (event.refresh) {
      _skip = 0;
      _hasMore = true;
      _items.clear();
      emit(PagedLoading<T>());
    } else {
      emit(PagedLoadingMore<T>(List.from(_items)));
    }

    try {
      final newItems = await fetchPage(skip: _skip, take: event.take ?? pageSize);

      if (event.refresh) {
        _items
          ..clear()
          ..addAll(newItems);
      } else {
        _items.addAll(newItems);
      }

      _skip += newItems.length;
      _hasMore = newItems.length == (event.take ?? pageSize);

      emit(PagedLoaded<T>(items: List.from(_items), hasMore: _hasMore, skip: _skip));
    } catch (e) {
      emit(PagedError<T>('Ошибка при загрузке: $e'));
    }
  }

  Future<void> _onRefreshPage(RefreshPage<T> event, Emitter<PagedState<T>> emit) async {
    add(LoadPage<T>(refresh: true, take: event.take));
  }
}

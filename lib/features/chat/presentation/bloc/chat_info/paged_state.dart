part of 'paged_bloc.dart';

abstract class PagedState<T> {}

class PagedInitial<T> extends PagedState<T> {}

class PagedLoading<T> extends PagedState<T> {}

class PagedLoadingMore<T> extends PagedState<T> {
  final List<T> items;

  PagedLoadingMore(this.items);
}

class PagedLoaded<T> extends PagedState<T> {
  final List<T> items;
  final bool hasMore;
  final int skip;

  PagedLoaded({required this.items, required this.hasMore, required this.skip});
}

class PagedError<T> extends PagedState<T> {
  final String message;

  PagedError(this.message);
}

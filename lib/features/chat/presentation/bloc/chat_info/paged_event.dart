part of 'paged_bloc.dart';

abstract class PagedEvent {}

class LoadPage<T> extends PagedEvent {
  final bool refresh;
  final int? take;

  LoadPage({this.refresh = false, this.take});
}

class RefreshPage<T> extends PagedEvent {
  final int? take;

  RefreshPage({this.take});
}

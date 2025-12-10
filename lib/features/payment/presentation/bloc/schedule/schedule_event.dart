part of 'schedule_bloc.dart';

@immutable
sealed class ScheduleEvent {}

class LoadSchedule extends ScheduleEvent {
  final bool refresh;
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final String? sortDirection;
  final String? clientName;
  final String? investorNickname;
  final int? creditId;
  final String? dateFrom;
  final String? dateTo;
  final String? search;
  final bool includePayed;

  LoadSchedule({
    this.refresh = false,
    this.page,
    this.pageSize,
    this.sortBy = 'date',
    this.sortDirection = 'asc',
    this.clientName,
    this.investorNickname,
    this.creditId,
    this.dateFrom,
    this.dateTo,
    this.search,
    this.includePayed = true,
  });
}

class SearchSchedule extends ScheduleEvent {
  final String query;
  final int? pageSize;

  SearchSchedule(this.query, {this.pageSize});
}

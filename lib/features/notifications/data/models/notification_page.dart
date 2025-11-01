import 'notification_model.dart';

class NotificationPage {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<NotificationModel> items;

  const NotificationPage({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  NotificationPage copyWith({List<NotificationModel>? items, int? totalCount}) {
    final newItems = items ?? this.items;
    return NotificationPage(
      page: page,
      pageSize: pageSize,
      totalCount: totalCount ?? newItems.length,
      totalPages: totalPages,
      items: newItems,
    );
  }

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'];
    final List<dynamic> list;
    if (rawItems is List) {
      list = rawItems;
    } else {
      list = const [];
    }

    return NotificationPage(
      page: _parseInt(json['page'] ?? json['Page']) ?? 0,
      pageSize: _parseInt(json['pageSize'] ?? json['PageSize']) ?? list.length,
      totalCount:
          _parseInt(json['totalCount'] ?? json['TotalCount']) ?? list.length,
      totalPages: _parseInt(json['totalPages'] ?? json['TotalPages']) ?? 1,
      items: list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

import 'black_catalog_client_model.dart';

class PagedBlackCatalogResult {
  const PagedBlackCatalogResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.totalItemsCount,
  });

  final List<BlackCatalogClientModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final int totalItemsCount;

  factory PagedBlackCatalogResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PagedBlackCatalogResult(
      items: rawItems
          .map((item) =>
              BlackCatalogClientModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: parseInt(json['page']),
      pageSize: parseInt(json['pageSize']),
      totalCount: parseInt(json['totalCount']),
      totalPages: parseInt(json['totalPages']),
      totalItemsCount: parseInt(json['totalItemsCount']),
    );
  }
}

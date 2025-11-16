import 'credit_application_model.dart';

class CreditApplicationPagedResult {
  const CreditApplicationPagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<CreditApplicationModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory CreditApplicationPagedResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .map(
          (item) => CreditApplicationModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    int? _toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return CreditApplicationPagedResult(
      items: items,
      page: _toInt(json['page']) ?? 1,
      pageSize: _toInt(json['pageSize']) ?? items.length,
      totalCount: _toInt(json['totalCount']) ?? items.length,
      totalPages: _toInt(json['totalPages']) ?? 1,
    );
  }
}

import 'package:waypay_mobile/features/bank_card/data/models/bank_card_model.dart';

class BankCardPagedResult {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<BankCardModel> items;

  BankCardPagedResult({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  factory BankCardPagedResult.fromJson(Map<String, dynamic> json) {
    return BankCardPagedResult(
      page: (json['page'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List? ?? [])
          .map((item) => BankCardModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'totalCount': totalCount,
      'totalPages': totalPages,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';

class InvestorPoolResponseModel {
  const InvestorPoolResponseModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<InvestorPoolModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory InvestorPoolResponseModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((e) => InvestorPoolModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return InvestorPoolResponseModel(
      items: items,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? items.length,
      totalCount: json['totalCount'] as int? ?? items.length,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

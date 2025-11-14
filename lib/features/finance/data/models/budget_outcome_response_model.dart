import 'package:waypay_mobile/features/finance/data/models/budget_outcome_model.dart';

class BudgetOutcomeResponseModel {
  final List<BudgetOutcomeModel> items;
  final int totalCount;
  final int page;
  final int pageSize;

  BudgetOutcomeResponseModel({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory BudgetOutcomeResponseModel.fromJson(Map<String, dynamic> json) {
    return BudgetOutcomeResponseModel(
      items: (json['items'] as List)
          .map((e) => BudgetOutcomeModel.fromJson(e))
          .toList(),
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}

import 'package:waypay/features/finance/data/models/budget_income_model.dart';

class BudgetIncomeResponseModel {
  final List<BudgetIncomeModel> items;
  final int totalCount;
  final int page;
  final int pageSize;

  BudgetIncomeResponseModel({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory BudgetIncomeResponseModel.fromJson(Map<String, dynamic> json) {
    return BudgetIncomeResponseModel(
      items: (json['items'] as List)
          .map((e) => BudgetIncomeModel.fromJson(e))
          .toList(),
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}

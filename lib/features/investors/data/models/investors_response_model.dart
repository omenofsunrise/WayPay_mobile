import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';

class InvestorsResponseModel {
  final List<InvestorsModel> investors;
  final int totalCount;
  final int page;
  final int pageSize;

  InvestorsResponseModel({
    required this.investors,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory InvestorsResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      List<dynamic> items = [];

      if (json['items'] != null) {
        items = json['items'] as List<dynamic>;
      } else if (json['data'] != null) {
        items = json['data'] as List<dynamic>;
      } else if (json is List) {
        items = json as List;
      } else {
        items = [];
      }

      final investors = items
          .map((item) => InvestorsModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return InvestorsResponseModel(
        investors: investors,
        totalCount: json['totalCount'] as int? ?? investors.length,
        page: json['page'] as int? ?? 1,
        pageSize: json['pageSize'] as int? ?? 10,
      );
    } catch (e) {
      rethrow;
    }
  }
}

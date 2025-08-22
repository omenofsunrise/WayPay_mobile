import 'package:waypay/features/credit/data/models/credit_model.dart';

class CreditResponseModel {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<CreditModel> items;

  CreditResponseModel({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  factory CreditResponseModel.fromJson(Map<String, dynamic> json) {
    return CreditResponseModel(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => CreditModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

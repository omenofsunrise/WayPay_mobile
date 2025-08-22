import 'package:waypay/features/finance/data/models/payment_model.dart';

class PaymentResponseModel {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<PaymentModel> items;

  PaymentResponseModel({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

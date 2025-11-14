import 'package:waypay_mobile/features/analytics/data/models/graph_data.dart';

class SellInfoResponse {
  final GraphData sellsSum;
  final GraphData purchasesSum;
  final GraphData cash;

  SellInfoResponse({
    required this.sellsSum,
    required this.purchasesSum,
    required this.cash,
  });

  factory SellInfoResponse.fromJson(Map<String, dynamic> json) {
    return SellInfoResponse(
      sellsSum: GraphData.fromJson(json['sellsSum']),
      purchasesSum: GraphData.fromJson(json['purchasesSum']),
      cash: GraphData.fromJson(json['cash']),
    );
  }

  Map<String, dynamic> toJson() => {
    'sellsSum': sellsSum.toJson(),
    'purchasesSum': purchasesSum.toJson(),
    'cash': cash.toJson(),
  };
}

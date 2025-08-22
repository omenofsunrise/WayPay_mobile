import 'package:waypay/features/analytics/data/models/graph_data.dart';

class DebtDynamicResponse {
  final GraphData paymentsDynamic;
  final GraphData debtDynamic;

  DebtDynamicResponse({
    required this.paymentsDynamic,
    required this.debtDynamic,
  });

  factory DebtDynamicResponse.fromJson(Map<String, dynamic> json) {
    return DebtDynamicResponse(
      paymentsDynamic: GraphData.fromJson(json['paymentsDynamic']),
      debtDynamic: GraphData.fromJson(json['debtDynamic']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentsDynamic': paymentsDynamic.toJson(),
      'debtDynamic': debtDynamic.toJson(),
    };
  }
}

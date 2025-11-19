import 'package:waypay_mobile/features/analytics/data/models/analytic_items_response.dart';
import 'package:waypay_mobile/features/analytics/data/models/debt_dynamic_response.dart';
import 'package:waypay_mobile/features/analytics/data/models/graph_data.dart';
import 'package:waypay_mobile/features/analytics/data/models/sell_info_response.dart';
import 'package:waypay_mobile/features/payment/data/models/payment_schedule_summary.dart';

abstract class AnalyticRemoteDataSource {
  Future<AnalyticItemsResponse> getAnalyticItems({
    String? start,
    String? end,
    String? predefinedPeriod,
  });
  Future<SellInfoResponse> getSellInfo({
    String? start,
    String? end,
    String? predefinedPeriod,
  });
  Future<GraphData> getInvestmentAmountDynamic({
    String? start,
    String? end,
    String? predefinedPeriod,
  });
  Future<DebtDynamicResponse> getDebtDynamic({
    String? start,
    String? end,
    String? predefinedPeriod,
  });
  Future<List<PaymentScheduleSummary>> getPaymentSchedules({int? year});
}

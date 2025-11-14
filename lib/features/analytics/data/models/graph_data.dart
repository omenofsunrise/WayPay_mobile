import 'package:waypay_mobile/features/analytics/data/models/period_value.dart';

class GraphData {
  final String graphName;
  final List<PeriodValue> periods;

  GraphData({required this.graphName, required this.periods});

  factory GraphData.fromJson(Map<String, dynamic> json) {
    return GraphData(
      graphName: json['graphName'] ?? '',
      periods: (json['periods'] as List<dynamic>? ?? [])
          .map((e) => PeriodValue.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'graphName': graphName,
    'periods': periods.map((e) => e.toJson()).toList(),
  };
}

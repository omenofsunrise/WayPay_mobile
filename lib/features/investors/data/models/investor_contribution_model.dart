class InvestorContributionModel {
  const InvestorContributionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.confirmed,
    this.investorNickname,
  });

  final int id;
  final double amount;
  final DateTime date;
  final bool confirmed;
  final String? investorNickname;

  factory InvestorContributionModel.fromJson(Map<String, dynamic> json) {
    return InvestorContributionModel(
      id: (json['id'] as num).toInt(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date:
          DateTime.tryParse(
            (json['date'] ?? json['createdAt'])?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      confirmed: json['confirmed'] as bool? ?? false,
      investorNickname: json['investorNickname'] as String?,
    );
  }
}

class InvestorContributionsPage {
  const InvestorContributionsPage({
    required this.items,
    required this.totalCount,
  });

  final List<InvestorContributionModel> items;
  final int totalCount;

  factory InvestorContributionsPage.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    final rawItems = json is List ? json : (map['items'] as List? ?? const []);
    final items = rawItems
        .whereType<Map>()
        .map(
          (item) => InvestorContributionModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
    return InvestorContributionsPage(
      items: items,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }
}

/// Где лежат деньги инвестора: в отдельной кассе или в пуле.
/// Бэкенд сериализует enum строкой ("Single" / "Pool").
enum InvestorCashPositionType {
  single('Single', 'Отдельная касса'),
  pool('Pool', 'В пуле');

  const InvestorCashPositionType(this.apiValue, this.title);

  final String apiValue;
  final String title;

  static InvestorCashPositionType fromApi(dynamic value) {
    if (value is String) {
      for (final type in InvestorCashPositionType.values) {
        if (type.apiValue.toLowerCase() == value.toLowerCase()) return type;
      }
    }
    if (value is num) {
      // На случай, если конвертер enum'ов отключат: Single = 1, Pool = 2.
      if (value.toInt() == 2) return InvestorCashPositionType.pool;
    }
    return InvestorCashPositionType.single;
  }
}

class InvestorCashPositionModel {
  const InvestorCashPositionModel({
    required this.id,
    required this.investorId,
    required this.position,
    required this.date,
    required this.createdAt,
    required this.investorNickname,
    this.poolId,
    this.poolName,
  });

  final int id;
  final int investorId;
  final InvestorCashPositionType position;
  final DateTime date;
  final DateTime createdAt;
  final String investorNickname;
  final int? poolId;
  final String? poolName;

  factory InvestorCashPositionModel.fromJson(Map<String, dynamic> json) {
    return InvestorCashPositionModel(
      id: (json['id'] as num).toInt(),
      investorId: (json['investorId'] as num).toInt(),
      position: InvestorCashPositionType.fromApi(json['position']),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      investorNickname: (json['investorNickname'] ?? '') as String,
      poolId: (json['poolId'] as num?)?.toInt(),
      poolName: json['poolName'] as String?,
    );
  }

  /// Подпись позиции для списка: пул показываем по имени, если оно пришло.
  String get label {
    if (position == InvestorCashPositionType.pool) {
      final name = (poolName ?? '').trim();
      return name.isEmpty ? 'В пуле' : 'В пуле «$name»';
    }
    return position.title;
  }
}

class InvestorCashPositionHistoryResponse {
  const InvestorCashPositionHistoryResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<InvestorCashPositionModel> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory InvestorCashPositionHistoryResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = (json['items'] ?? json['data'] ?? const []) as List<dynamic>;
    final items = raw
        .map(
          (e) => InvestorCashPositionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();

    return InvestorCashPositionHistoryResponse(
      items: items,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );
  }
}

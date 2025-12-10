enum PaymentType { cash, card }

PaymentType paymentTypeFromString(String value) {
  switch (value) {
    case 'cash':
      return PaymentType.cash;
    case 'card':
      return PaymentType.card;
    default:
      throw Exception('Unknown payment type: $value');
  }
}

String paymentTypeToString(PaymentType type) {
  switch (type) {
    case PaymentType.cash:
      return 'cash';
    case PaymentType.card:
      return 'card';
  }
}

class PaymentItemModel {
  final int id;
  final int creditId;
  final double paymentAmount;
  final String paymentDate;
  final PaymentType type;
  final bool accepted;
  final String clientFullName;
  final String? investorNickname;
  final String? employeeFullName;
  final double income;

  PaymentItemModel({
    required this.id,
    required this.creditId,
    required this.paymentAmount,
    required this.paymentDate,
    required this.type,
    required this.accepted,
    required this.clientFullName,
    this.investorNickname,
    this.employeeFullName,
    required this.income,
  });

  factory PaymentItemModel.fromJson(Map<String, dynamic> json) {
    return PaymentItemModel(
      id: json['id'] ?? 0,
      creditId: json['creditId'] ?? 0,
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0,
      paymentDate: json['paymentDate'] ?? '',
      type: json['type'] != null
          ? paymentTypeFromString(json['type'])
          : PaymentType.cash,
      accepted: json['accepted'] ?? false,
      clientFullName: json['clientFullName'] ?? '',
      investorNickname: json['investorNickname'],
      employeeFullName: json['employeeFullName'],
      income: (json['income'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'creditId': creditId,
    'paymentAmount': paymentAmount,
    'paymentDate': paymentDate,
    'type': paymentTypeToString(type),
    'accepted': accepted,
    'clientFullName': clientFullName,
    'investorNickname': investorNickname,
    'employeeFullName': employeeFullName,
    'income': income,
  };
}

class PaymentListResponseModel {
  final double totalPayments;
  final int totalIncome;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<PaymentItemModel> items;

  PaymentListResponseModel({
    required this.totalPayments,
    required this.totalIncome,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  factory PaymentListResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentListResponseModel(
      totalPayments: (json['totalPayments'] as num?)?.toDouble() ?? 0,
      totalIncome: (json['totalIncome'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List? ?? [])
          .map((item) => PaymentItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalPayments': totalPayments,
    'totalIncome': totalIncome,
    'page': page,
    'pageSize': pageSize,
    'totalCount': totalCount,
    'totalPages': totalPages,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

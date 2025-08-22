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
      id: json['id'],
      creditId: json['creditId'],
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      paymentDate: json['paymentDate'],
      type: paymentTypeFromString(json['type']),
      accepted: json['accepted'],
      clientFullName: json['clientFullName'],
      investorNickname: json['investorNickname'],
      employeeFullName: json['employeeFullName'],
      income: (json['income'] as num).toDouble(),
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
      totalPayments: (json['totalPayments'] as num).toDouble(),
      totalIncome: json['totalIncome'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalCount: json['totalCount'],
      totalPages: json['totalPages'],
      items: (json['items'] as List)
          .map((item) => PaymentItemModel.fromJson(item))
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

class ScheduleModel {
  final int id;
  final int creditId;
  final double rest;
  final double paymentAmount;
  final String paymentDate;
  final String comment;
  final bool notified;
  final String clientName;
  final String clientPhone;
  final bool payed;

  ScheduleModel({
    required this.id,
    required this.creditId,
    required this.rest,
    required this.paymentAmount,
    required this.paymentDate,
    required this.comment,
    required this.notified,
    required this.clientName,
    required this.clientPhone,
    this.payed = false,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      creditId: json['creditId'],
      rest: (json['rest'] as num).toDouble(),
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      paymentDate: json['paymentDate'] ?? '',
      comment: json['comment'] ?? '',
      notified: json['notified'] ?? false,
      clientName: json['clientName'] ?? '',
      clientPhone: json['clientPhone'] ?? '',
      payed: json['payed'] ?? json['paid'] ?? false,
    );
  }

  ScheduleModel copyWith({
    int? id,
    int? creditId,
    double? rest,
    double? paymentAmount,
    String? paymentDate,
    String? comment,
    bool? notified,
    String? clientName,
    String? clientPhone,
    bool? payed,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      creditId: creditId ?? this.creditId,
      rest: rest ?? this.rest,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      comment: comment ?? this.comment,
      notified: notified ?? this.notified,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      payed: payed ?? this.payed,
    );
  }
}

class ScheduleResponseModel {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<ScheduleModel> items;

  ScheduleResponseModel({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  factory ScheduleResponseModel.fromJson(Map<String, dynamic> json) {
    return ScheduleResponseModel(
      page: json['page'],
      pageSize: json['pageSize'],
      totalCount: json['totalCount'],
      totalPages: json['totalPages'],
      items: (json['items'] as List<dynamic>).map((item) => ScheduleModel.fromJson(item)).toList(),
    );
  }
}

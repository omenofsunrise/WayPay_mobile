class SchedulePreviewModel {
  final DateTime paymentDate;
  final double paymentAmount;
  final double rest;
  final String? comment;

  SchedulePreviewModel({
    required this.paymentDate,
    required this.paymentAmount,
    required this.rest,
    this.comment,
  });

  factory SchedulePreviewModel.fromJson(Map<String, dynamic> json) {
    return SchedulePreviewModel(
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      rest: (json['rest'] as num).toDouble(),
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentDate': paymentDate.toIso8601String(),
      'paymentAmount': paymentAmount,
      'rest': rest,
      'comment': comment,
    };
  }
}

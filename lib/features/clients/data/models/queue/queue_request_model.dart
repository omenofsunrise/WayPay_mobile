class QueueRequestModel {
  final double sum;
  final int clientId;
  final int priority;

  QueueRequestModel({required this.sum, required this.clientId, required this.priority});

  Map<String, dynamic> toJson() => {'sum': sum, 'clientId': clientId, 'priority': priority};
}

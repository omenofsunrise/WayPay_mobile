import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';

class QueueItemModel {
  final int id;
  final double sum;
  final int clientId;
  final DateTime createdAt;
  final int priority;
  final int positionInQueue;
  ClientModel? client;

  QueueItemModel({
    required this.id,
    required this.sum,
    required this.clientId,
    required this.createdAt,
    required this.priority,
    required this.positionInQueue,
    this.client,
  });

  factory QueueItemModel.fromJson(Map<String, dynamic> json) {
    return QueueItemModel(
      id: json['id'],
      sum: (json['sum'] as num).toDouble(),
      clientId: json['clientId'],
      createdAt: DateTime.parse(json['createdAt']),
      priority: json['priority'],
      positionInQueue: json['positionInQueue'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sum': sum,
    'clientId': clientId,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority,
    'positionInQueue': positionInQueue,
  };
}

class QueueResponseModel {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final List<QueueItemModel> items;

  QueueResponseModel({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.items,
  });

  factory QueueResponseModel.fromJson(Map<String, dynamic> json) {
    return QueueResponseModel(
      page: json['page'],
      pageSize: json['pageSize'],
      totalCount: json['totalCount'],
      totalPages: json['totalPages'],
      items: (json['items'] as List)
          .map((e) => QueueItemModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'page': page,
    'pageSize': pageSize,
    'totalCount': totalCount,
    'totalPages': totalPages,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

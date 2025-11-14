import 'client_model.dart';

class ClientsResponseModel {
  final List<ClientModel> clients;
  final int totalCount;
  final int page;
  final int pageSize;

  ClientsResponseModel({
    required this.clients,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory ClientsResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      List<dynamic> items = [];

      if (json['items'] != null) {
        items = json['items'] as List<dynamic>;
      } else if (json['data'] != null) {
        items = json['data'] as List<dynamic>;
      } else if (json is List) {
        items = json as List;
      } else {
        items = [];
      }

      final clients = items
          .map((item) => ClientModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ClientsResponseModel(
        clients: clients,
        totalCount: json['totalCount'] as int? ?? clients.length,
        page: json['page'] as int? ?? 1,
        pageSize: json['pageSize'] as int? ?? 20,
      );
    } catch (e) {
      rethrow;
    }
  }
}

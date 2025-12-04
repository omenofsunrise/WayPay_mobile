import 'dart:convert';

class BudgetIncomeModel {
  final int id;
  final double amount;
  final String? comment;
  final int? investorId;
  final DateTime? createdAt;
  final String? investorName;

  BudgetIncomeModel({
    required this.id,
    required this.amount,
    this.comment,
    this.investorId,
    required this.createdAt,
    this.investorName,
  });

  factory BudgetIncomeModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['date'] as String?;
    DateTime? createdAt;

    if (createdAtRaw != null && createdAtRaw.trim().isNotEmpty) {
      createdAt = DateTime.parse(createdAtRaw);
    } else {
      createdAt = null;
    }

    String? resolvedComment;
    final request = json['request'];
    if (request is Map<String, dynamic>) {
      resolvedComment = request['comment'] as String?;
    } else if (request is String && request.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(request);
        if (decoded is Map<String, dynamic>) {
          resolvedComment = decoded['comment'] as String?;
        }
      } catch (_) {
        resolvedComment = null;
      }
    }

    String? investorName = json['investorNickname'] as String?;
    final investorJson = json['investor'];
    if (investorName == null && investorJson is Map<String, dynamic>) {
      investorName =
          (investorJson['nickname'] as String?) ??
          (investorJson['fullName'] as String?);
    }

    return BudgetIncomeModel(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      comment: (json['comment'] as String?) ??
          (json['description'] as String?) ??
          (json['comments'] as String?) ??
          resolvedComment,
      investorId: json['investorId'] as int?,
      createdAt: createdAt,
      investorName: investorName,
    );
  }
}

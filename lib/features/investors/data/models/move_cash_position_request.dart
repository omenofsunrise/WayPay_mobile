import 'package:waypay_mobile/features/investors/data/models/investor_cash_position_model.dart';

class MoveCashPositionRequest {
  const MoveCashPositionRequest({
    required this.investorId,
    required this.newPositionType,
    required this.date,
    this.poolId,
  });

  final int investorId;
  final InvestorCashPositionType newPositionType;

  /// Дата перевода. Отправляем полночь UTC: сервер делает ToUniversalTime(),
  /// и локальная дата уехала бы на сутки назад.
  final DateTime date;

  final int? poolId;

  Map<String, dynamic> toJson() => {
    'investorId': investorId,
    'newPositionType': newPositionType.apiValue,
    'poolId': newPositionType == InvestorCashPositionType.pool ? poolId : null,
    'date': date.toUtc().toIso8601String(),
  };
}

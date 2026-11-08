import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_contribution_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_request.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';

void main() {
  test('выплата разбирает источник и статус подтверждения', () {
    final payout = InvestorPayoutModel.fromJson({
      'id': 10,
      'investorId': 7,
      'investorFullName': 'Иванов Иван',
      'employeeFullName': 'Менеджер',
      'amount': 12500,
      'payoutDate': '2026-11-09T12:00:00Z',
      'payoutSource': 'Investment',
      'confirmed': true,
    });

    expect(payout.id, 10);
    expect(payout.investorId, 7);
    expect(payout.payoutSource, 'investment');
    expect(payout.confirmed, isTrue);
  });

  test('запрос выплаты передаёт выбранный источник', () {
    final json = InvestorPayoutRequest(
      investorId: 7,
      amount: 5000,
      payoutSource: 'income',
    ).toJson();

    expect(json, {
      'investorId': 7,
      'amount': 5000.0,
      'payoutSource': 'income',
    });
  });

  test('страница инвестиций поддерживает пагинированный ответ', () {
    final page = InvestorContributionsPage.fromJson({
      'totalCount': 1,
      'items': [
        {
          'id': 3,
          'amount': 8400,
          'date': '2026-11-01T12:00:00Z',
          'confirmed': false,
          'investorNickname': 'Тест',
        },
      ],
    });

    expect(page.totalCount, 1);
    expect(page.items.single.amount, 8400);
    expect(page.items.single.confirmed, isFalse);
  });

  test('пул разбирает признак кассы компании', () {
    final pool = InvestorPoolModel.fromJson({
      'id': 2,
      'name': 'Общая касса',
      'balance': 100000,
      'selfIncome': 5000,
      'createdAt': '2026-01-01T00:00:00Z',
      'isCompanyPool': true,
    });

    expect(pool.isCompanyPool, isTrue);
    expect(pool.balance, 100000);
  });
}

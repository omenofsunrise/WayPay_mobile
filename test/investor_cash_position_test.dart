import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_cash_position_model.dart';
import 'package:waypay_mobile/features/investors/data/models/move_cash_position_request.dart';

void main() {
  group('InvestorCashPositionModel.fromJson', () {
    test('разбирает позицию «отдельная касса»', () {
      final model = InvestorCashPositionModel.fromJson({
        'id': 11,
        'investorId': 1045,
        'poolId': null,
        'position': 'Single',
        'date': '2026-09-20T00:00:00Z',
        'createdAt': '2026-09-20T12:30:00Z',
        'investorNickname': 'Лайс',
        'poolName': null,
      });

      expect(model.id, 11);
      expect(model.investorId, 1045);
      expect(model.position, InvestorCashPositionType.single);
      expect(model.poolId, isNull);
      expect(model.poolName, isNull);
      expect(model.investorNickname, 'Лайс');
      expect(model.date.toUtc(), DateTime.utc(2026, 9, 20));
    });

    test('разбирает позицию «в пуле»', () {
      final model = InvestorCashPositionModel.fromJson({
        'id': 12,
        'investorId': 1045,
        'poolId': 170,
        'position': 'Pool',
        'date': '2026-09-21T00:00:00Z',
        'createdAt': '2026-09-21T09:00:00Z',
        'investorNickname': 'Лайс',
        'poolName': 'Bart Finance',
      });

      expect(model.position, InvestorCashPositionType.pool);
      expect(model.poolId, 170);
      expect(model.poolName, 'Bart Finance');
    });

    test('неизвестный тип позиции не роняет разбор', () {
      final model = InvestorCashPositionModel.fromJson({
        'id': 13,
        'investorId': 1,
        'position': 'Whatever',
        'date': '2026-09-21T00:00:00Z',
        'createdAt': '2026-09-21T09:00:00Z',
        'investorNickname': 'X',
      });

      expect(model.position, InvestorCashPositionType.single);
    });
  });

  group('InvestorCashPositionHistoryResponse.fromJson', () {
    test('разбирает страницу истории', () {
      final response = InvestorCashPositionHistoryResponse.fromJson({
        'items': [
          {
            'id': 1,
            'investorId': 5,
            'poolId': 170,
            'position': 'Pool',
            'date': '2026-09-21T00:00:00Z',
            'createdAt': '2026-09-21T09:00:00Z',
            'investorNickname': 'Лайс',
            'poolName': 'Bart Finance',
          },
        ],
        'totalCount': 23,
        'page': 2,
        'pageSize': 10,
      });

      expect(response.items, hasLength(1));
      expect(response.totalCount, 23);
      expect(response.page, 2);
      expect(response.pageSize, 10);
      expect(response.items.first.poolName, 'Bart Finance');
    });

    test('пустой ответ даёт пустой список', () {
      final response = InvestorCashPositionHistoryResponse.fromJson({});

      expect(response.items, isEmpty);
      expect(response.totalCount, 0);
    });
  });

  group('MoveCashPositionRequest.toJson', () {
    test('перевод в пул отдаёт poolId и строковый тип', () {
      final request = MoveCashPositionRequest(
        investorId: 1045,
        newPositionType: InvestorCashPositionType.pool,
        poolId: 170,
        date: DateTime.utc(2026, 9, 26),
      );

      expect(request.toJson(), {
        'investorId': 1045,
        'newPositionType': 'Pool',
        'poolId': 170,
        'date': '2026-09-26T00:00:00.000Z',
      });
    });

    test('перевод в отдельную кассу отдаёт poolId = null', () {
      final request = MoveCashPositionRequest(
        investorId: 1045,
        newPositionType: InvestorCashPositionType.single,
        date: DateTime.utc(2026, 9, 26),
      );

      final json = request.toJson();
      expect(json['newPositionType'], 'Single');
      expect(json['poolId'], isNull);
    });
  });
}

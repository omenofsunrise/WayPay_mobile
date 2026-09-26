import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';

void main() {
  group('GetCreditsQuery — фильтры, которых не хватало против веба', () {
    test('номер договора уходит как name', () {
      final params = GetCreditsQuery(name: '№1234').toQueryParams();
      expect(params['name'], '№1234');
    });

    test('адрес клиента', () {
      final params = GetCreditsQuery(clientAddress: 'Гудермес').toQueryParams();
      expect(params['clientAddress'], 'Гудермес');
    });

    test('даты создания договора', () {
      final params = GetCreditsQuery(
        createdAt: DateTime.utc(2026, 9, 1),
        createdTo: DateTime.utc(2026, 9, 30),
      ).toQueryParams();

      expect(params['createdAt'], '2026-09-01T00:00:00.000Z');
      expect(params['createdTo'], '2026-09-30T00:00:00.000Z');
    });

    test('источник инвестиций — пул', () {
      final params = GetCreditsQuery(investorPoolId: 170).toQueryParams();
      expect(params['investorPoolId'], 170);
    });

    test('тип объекта', () {
      final params = GetCreditsQuery(objectTypeId: 5).toQueryParams();
      expect(params['objectTypeId'], 5);
    });

    test('переключатели: в долг, расторгнутые, мои', () {
      final params = GetCreditsQuery(
        inDebt: true,
        terminated: true,
        myCredits: true,
      ).toQueryParams();

      expect(params['inDebt'], isTrue);
      expect(params['terminated'], isTrue);
      expect(params['myCredits'], isTrue);
    });

    test('незаданные фильтры в запрос не попадают', () {
      final params = GetCreditsQuery(page: 1).toQueryParams();

      for (final key in [
        'name',
        'clientAddress',
        'createdAt',
        'createdTo',
        'investorPoolId',
        'objectTypeId',
        'inDebt',
        'terminated',
        'myCredits',
      ]) {
        expect(params.containsKey(key), isFalse, reason: 'лишний ключ $key');
      }
    });

    test('copyWith сохраняет новые поля', () {
      final query = GetCreditsQuery(
        name: '№7',
        clientAddress: 'Аргун',
        objectTypeId: 3,
        inDebt: true,
      );

      final copy = query.copyWith(page: 2);

      expect(copy.page, 2);
      expect(copy.name, '№7');
      expect(copy.clientAddress, 'Аргун');
      expect(copy.objectTypeId, 3);
      expect(copy.inDebt, isTrue);
    });
  });
}

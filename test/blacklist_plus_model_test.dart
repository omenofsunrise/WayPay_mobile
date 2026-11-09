import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/features/clients/data/models/blacklist_plus_model.dart';

void main() {
  test('ЧС+ разбирает результаты поиска и долги', () {
    final result = BlacklistPlusSearchResult.fromJson({
      'totalItemsCount': 1,
      'items': [
        {
          'id': 7,
          'fullName': 'Иванов Иван',
          'phone': '79990000000',
          'doc': '1234 567890',
          'birthdate': '1990-05-12T00:00:00Z',
          'isSwindler': true,
          'debts': [
            {'payed': false, 'debtEndingAt': '2026-11-09T00:00:00Z'},
          ],
        },
      ],
    });

    expect(result.totalCount, 1);
    expect(result.items.single.fullName, 'Иванов Иван');
    expect(result.items.single.isSwindler, isTrue);
    expect(result.items.single.debts.single.paid, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/core/widgets/search/search_destinations.dart';

void main() {
  test('navigation menu contains only unique relevant destinations', () {
    final destinations = getDefaultSearchDestinations();
    final titles = destinations
        .map((destination) => destination.title)
        .toList();

    expect(titles.toSet().length, titles.length);
    expect(titles, isNot(contains('Платежи (ожидаемые)')));
    expect(titles, isNot(contains('Калькулятор')));
    expect(titles, isNot(contains('Профиль')));
    expect(titles, containsAll(<String>['Все клиенты', 'Заявки клиентов']));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

void main() {
  testWidgets('общая модалка показывает содержимое и действия', (tester) async {
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WayPayModal(
            title: 'Заголовок',
            subtitle: 'Подзаголовок',
            onClose: () {},
            primaryText: 'Готово',
            onPrimary: () => saved = true,
            child: const Text('Содержимое'),
          ),
        ),
      ),
    );

    expect(find.text('Заголовок'), findsOneWidget);
    expect(find.text('Подзаголовок'), findsOneWidget);
    expect(find.text('Содержимое'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);

    await tester.tap(find.text('Готово'));
    expect(saved, isTrue);
  });
}

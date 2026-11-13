import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/core/app_mode/app_mode_selection_screen.dart';

void main() {
  testWidgets('service selector shows both applications', (tester) async {
    await tester.pumpWidget(const AppModeSelectionScreen());

    expect(find.text('Выберите сервис'), findsOneWidget);
    expect(find.text('WayPay CRM'), findsOneWidget);
    expect(find.text('ЧС+'), findsOneWidget);
  });
}

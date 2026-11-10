import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/core/notifications/notification_presentation.dart';
import 'package:waypay_mobile/core/widgets/in_app_notification_banner.dart';

void main() {
  test('formats WhatsApp phone like the website', () {
    expect(formatNotificationPhone('89281234567'), '+7 928 123-45-67');
    expect(formatNotificationPhone('9281234567'), '+7 928 123-45-67');
  });

  test('resolves relative notification images against file storage', () {
    expect(
      resolveNotificationImageUrl('/avatars/a.png'),
      'https://web.waypay.one:5002/avatars/a.png',
    );
    expect(
      resolveNotificationImageUrl('https://cdn.test/a.png'),
      'https://cdn.test/a.png',
    );
  });

  testWidgets('keeps at most five visible notifications', (tester) async {
    late OverlayState overlay;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            overlay = Overlay.of(context);
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    for (var index = 0; index < 6; index++) {
      showInAppNotification(
        overlay,
        title: 'Уведомление $index',
        body: 'Текст $index',
      );
    }
    await tester.pump();

    expect(find.text('Уведомление 0'), findsNothing);
    for (var index = 1; index < 6; index++) {
      expect(find.text('Уведомление $index'), findsOneWidget);
    }

    hideAllInAppNotifications();
    await tester.pump();
  });

  testWidgets('renders WhatsApp title and campaign badge', (tester) async {
    late OverlayState overlay;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            overlay = Overlay.of(context);
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    showInAppNotification(
      overlay,
      title: '89281234567',
      body: 'Ответ клиента',
      type: 'admin_whats_app',
    );
    await tester.pump();

    final renderError = tester.takeException();
    expect(renderError, isNull, reason: renderError?.toString());

    expect(find.text('+7 928 123-45-67'), findsOneWidget);
    expect(find.text('📣 Ответ на рекламу'), findsOneWidget);

    hideAllInAppNotifications();
    await tester.pump();
  });
}

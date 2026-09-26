import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/core/network/socket_notification_message.dart';

void main() {
  group('SocketNotificationMessage.fromJson', () {
    test('разбирает сообщение в PascalCase — так его шлёт бэкенд', () {
      final message = SocketNotificationMessage.fromJson({
        'Type': 'notification',
        'Title': 'Напоминание',
        'Body': 'Позвонить клиенту',
        'Image': null,
        'Route': 'credits/12345',
        'Timestamp': '2026-09-27T09:00:00Z',
      });

      expect(message.type, 'notification');
      expect(message.title, 'Напоминание');
      expect(message.body, 'Позвонить клиенту');
      expect(message.route, 'credits/12345');
      expect(message.image, isNull);
      expect(message.timestamp?.toUtc(), DateTime.utc(2026, 9, 27, 9));
    });

    test('понимает и camelCase, если на бэкенде включат политику имён', () {
      final message = SocketNotificationMessage.fromJson({
        'type': 'notification',
        'title': 'Напоминание',
        'body': 'Текст',
        'route': 'credits/7',
      });

      expect(message.title, 'Напоминание');
      expect(message.body, 'Текст');
      expect(message.route, 'credits/7');
    });

    test('пустые поля не роняют разбор', () {
      final message = SocketNotificationMessage.fromJson({});

      expect(message.type, 'notification');
      expect(message.title, '');
      expect(message.body, '');
      expect(message.route, isNull);
      expect(message.timestamp, isNull);
    });

    test('битую дату отдаёт как null, а не падает', () {
      final message = SocketNotificationMessage.fromJson({
        'Title': 'Т',
        'Body': 'Б',
        'Timestamp': 'не дата',
      });

      expect(message.timestamp, isNull);
      expect(message.title, 'Т');
    });

    test('id договора вынимается из маршрута', () {
      expect(
        SocketNotificationMessage.fromJson({'Route': 'credits/12345'}).creditId,
        12345,
      );
      expect(
        SocketNotificationMessage.fromJson({'Route': 'clients/9'}).creditId,
        isNull,
      );
      expect(SocketNotificationMessage.fromJson({}).creditId, isNull);
    });
  });

  group('SocketAuthMessage', () {
    test('рукопожатие шлёт EmployeeId в PascalCase', () {
      expect(const SocketAuthMessage(employeeId: 28).toJson(), {
        'EmployeeId': 28,
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/features/credit/data/models/schedule_preview_request.dart';

void main() {
  group('SchedulePreviewRequest.toJson', () {
    test('передаёт дату начала выплат — без неё бэкенд берёт DateTime.MinValue',
        () {
      final request = SchedulePreviewRequest(
        totalAmount: 598125,
        firstPayment: 119625,
        termMonths: 4,
        startDate: DateTime(2026, 9, 26),
      );

      final json = request.toJson();

      expect(json['startDate'], '2026-09-26T00:00:00.000');
      expect(json['totalAmount'], 598125);
      expect(json['firstPayment'], 119625);
      expect(json['termMonths'], 4);
    });

    test('не отправляет поля, которых бэкенд не читает', () {
      final json = SchedulePreviewRequest(
        totalAmount: 100,
        firstPayment: 0,
        termMonths: 1,
        startDate: DateTime(2026, 1, 1),
      ).toJson();

      expect(json.containsKey('paymentDay'), isFalse);
      expect(json.containsKey('currentMonthStart'), isFalse);
      expect(json.containsKey('nextMonthStart'), isFalse);
    });

    test('время суток отбрасывается: бэкенду нужен только день', () {
      final json = SchedulePreviewRequest(
        totalAmount: 100,
        firstPayment: 0,
        termMonths: 1,
        startDate: DateTime(2026, 9, 26, 17, 43, 12),
      ).toJson();

      expect(json['startDate'], '2026-09-26T00:00:00.000');
    });

    test('передаёт отключение округления', () {
      final json = SchedulePreviewRequest(
        totalAmount: 100,
        firstPayment: 0,
        termMonths: 1,
        startDate: DateTime(2026, 1, 1),
        turnOfRounding: true,
      ).toJson();

      expect(json['turnOfRounding'], isTrue);
    });
  });
}

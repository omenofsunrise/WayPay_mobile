/// Тело запроса `POST Schedule/preview`.
///
/// Бэкенд читает ровно четыре поля плюс флаг округления
/// (`SchedulePreviewRequest` в WayPay_back). Раньше приложение отправляло
/// `paymentDay`, `currentMonthStart` и `nextMonthStart`, которых в контракте нет,
/// и не отправляло `startDate`. Из-за этого сервер подставлял
/// `DateTime.MinValue`, и превью показывало график от 01.01.0001.
class SchedulePreviewRequest {
  const SchedulePreviewRequest({
    required this.totalAmount,
    required this.firstPayment,
    required this.termMonths,
    required this.startDate,
    this.turnOfRounding = false,
  });

  final double totalAmount;
  final double firstPayment;
  final int termMonths;
  final DateTime startDate;
  final bool turnOfRounding;

  Map<String, dynamic> toJson() => {
    'totalAmount': totalAmount,
    'firstPayment': firstPayment,
    'termMonths': termMonths,
    // Генератор берёт только год, месяц и день, поэтому время отбрасываем —
    // иначе оно шумит в логах и мешает сравнивать превью с сохранённым графиком.
    'startDate': DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).toIso8601String(),
    'turnOfRounding': turnOfRounding,
  };
}

/// Сообщение, которое бэкенд присылает по WebSocket `/ws`.
///
/// Соответствует `NotificationMessage` в WayPay_back. Сериализуется через
/// `JsonSerializer.Serialize` без политики имён, поэтому ключи в PascalCase —
/// так же их читает веб (`useWebSocket.ts`). camelCase принимаем на случай,
/// если политику однажды включат.
class SocketNotificationMessage {
  const SocketNotificationMessage({
    required this.type,
    required this.title,
    required this.body,
    this.image,
    this.route,
    this.timestamp,
  });

  final String type;
  final String title;
  final String body;
  final String? image;
  final String? route;
  final DateTime? timestamp;

  static String? _str(Map<String, dynamic> json, String pascal) {
    final camel = pascal[0].toLowerCase() + pascal.substring(1);
    final value = json[pascal] ?? json[camel];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  factory SocketNotificationMessage.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = _str(json, 'Timestamp');

    return SocketNotificationMessage(
      type: _str(json, 'Type') ?? 'notification',
      title: _str(json, 'Title') ?? '',
      body: _str(json, 'Body') ?? '',
      image: _str(json, 'Image'),
      route: _str(json, 'Route'),
      timestamp: rawTimestamp == null ? null : DateTime.tryParse(rawTimestamp),
    );
  }

  /// Бэкенд кладёт в маршрут `credits/{id}` — по тапу открываем этот договор.
  int? get creditId {
    final value = route;
    if (value == null) return null;
    final match = RegExp(r'^credits/(\d+)$').firstMatch(value.trim());
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}

/// Рукопожатие: сразу после открытия соединения веб отправляет id сотрудника,
/// и бэкенд привязывает соединение к нему. Повторяем ровно это.
class SocketAuthMessage {
  const SocketAuthMessage({required this.employeeId});

  final int employeeId;

  Map<String, dynamic> toJson() => {'EmployeeId': employeeId};
}

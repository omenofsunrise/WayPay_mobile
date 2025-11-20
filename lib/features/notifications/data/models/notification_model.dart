class NotificationModel {
  final int id;
  final String? title;
  final String? message;
  final String? senderFullname;
  final String? senderAvatarPath;
  final DateTime dateTime;
  final bool isRead;
  final String? route;
  final String? type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.senderFullname,
    required this.senderAvatarPath,
    required this.dateTime,
    required this.isRead,
    required this.route,
    required this.type,
  });

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      senderFullname: senderFullname,
      senderAvatarPath: senderAvatarPath,
      dateTime: dateTime,
      isRead: isRead ?? this.isRead,
      route: route,
      type: type,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final isReadValue = json['isRead'] ?? json['IsRead'];
    return NotificationModel(
      id: _parseInt(json['id'] ?? json['Id']),
      title: (json['title'] ?? json['Title']) as String?,
      message: (json['message'] ?? json['Message']) as String?,
      senderFullname:
          (json['senderFullname'] ?? json['SenderFullname']) as String?,
      senderAvatarPath:
          (json['senderAvatarPath'] ?? json['SenderAvatarPath']) as String?,
      dateTime: DateTime.tryParse(
            (json['dateTime'] ?? json['DateTime']) as String? ?? '',
          ) ??
          DateTime.now(),
      isRead: _parseBool(isReadValue),
      route: (json['route'] ?? json['Route']) as String?,
      type: (json['type'] ?? json['Type']) as String?,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }
}

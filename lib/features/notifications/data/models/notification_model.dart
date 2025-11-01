class NotificationModel {
  final int id;
  final String? title;
  final String? message;
  final String? senderFullname;
  final String? senderAvatarPath;
  final DateTime dateTime;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.senderFullname,
    required this.senderAvatarPath,
    required this.dateTime,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _parseInt(json['id'] ?? json['Id']),
      title: (json['title'] ?? json['Title']) as String?,
      message: (json['message'] ?? json['Message']) as String?,
      senderFullname:
          (json['senderFullname'] ?? json['SenderFullname']) as String?,
      senderAvatarPath:
          (json['senderAvatarPath'] ?? json['SenderAvatarPath']) as String?,
      dateTime:
          DateTime.tryParse(
            (json['dateTime'] ?? json['DateTime']) as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

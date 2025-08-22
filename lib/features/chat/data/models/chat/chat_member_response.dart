DateTime? _parseDate(String? s) => s == null ? null : DateTime.parse(s);
String? _dateToJson(DateTime? d) => d?.toUtc().toIso8601String();

enum EmployeeRole {
  bukhgalter('бухгалтер'),
  sotrudnik('сотрудник'),
  admin('админ'),
  superadmin('суперадмин'),
  direktor('директор');

  final String json;
  const EmployeeRole(this.json);

  static EmployeeRole? fromJson(String? value) {
    if (value == null) return null;
    return EmployeeRole.values.firstWhere((r) => r.json == value, orElse: () => EmployeeRole.sotrudnik);
  }

  String toJson() => json;

  @override
  String toString() {
    if (json.isEmpty) return '';
    return json[0].toUpperCase() + json.substring(1);
  }
}

class ChatMemberResponse {
  final int id;
  final String? fullName;
  final String? photoPath;
  final DateTime? lastOnlineAt;
  final EmployeeRole role;

  const ChatMemberResponse({required this.id, this.fullName, this.photoPath, this.lastOnlineAt, required this.role});

  ChatMemberResponse copyWith({
    int? id,
    String? fullName,
    String? photoPath,
    DateTime? lastOnlineAt,
    EmployeeRole? role,
  }) => ChatMemberResponse(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    photoPath: photoPath ?? this.photoPath,
    lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
    role: role ?? this.role,
  );

  factory ChatMemberResponse.fromJson(Map<String, dynamic> json) => ChatMemberResponse(
    id: (json['id'] as num).toInt(),
    fullName: json['fullName'] as String?,
    photoPath: json['photoPath'] as String?,
    lastOnlineAt: _parseDate(json['lastOnlineAt'] as String?),
    role: EmployeeRole.fromJson(json['role'] as String?) ?? EmployeeRole.sotrudnik,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'photoPath': photoPath,
    'lastOnlineAt': _dateToJson(lastOnlineAt),
    'role': role.toJson(),
  };
}

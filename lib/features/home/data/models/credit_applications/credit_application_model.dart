class CreditApplicationModel {
  const CreditApplicationModel({
    required this.id,
    this.productName,
    this.productPrice,
    this.firstPayment,
    this.termMonths,
    this.region,
    this.district,
    this.createdDate,
    this.clientId,
    this.fullName,
    this.avatarPath,
    this.monthlyPayment,
    this.markupAmount,
    this.totalAmount,
    this.isMine = false,
    this.managerName,
    this.applicationNumber,
  });

  final int id;
  final String? productName;
  final double? productPrice;
  final double? firstPayment;
  final int? termMonths;
  final String? region;
  final String? district;
  final DateTime? createdDate;
  final int? clientId;
  final String? fullName;
  final String? avatarPath;
  final double? monthlyPayment;
  final double? markupAmount;
  final double? totalAmount;
  final bool isMine;
  final String? managerName;
  final String? applicationNumber;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory CreditApplicationModel.fromJson(Map<String, dynamic> json) {
    String? resolveManager() {
      return json['managerName'] as String? ??
          json['managerFullName'] as String? ??
          json['employeeName'] as String?;
    }

    return CreditApplicationModel(
      id: _toInt(json['id']) ?? 0,
      productName: json['productName'] as String?,
      productPrice: _toDouble(json['productPrice']),
      firstPayment: _toDouble(json['firstPayment']),
      termMonths: _toInt(json['termMonths']),
      region: json['region'] as String?,
      district: json['district'] as String?,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'].toString())
          : null,
      clientId: _toInt(json['clientId']),
      fullName: json['fullname'] as String? ??
          json['fullName'] as String? ??
          json['clientFullName'] as String?,
      avatarPath: json['avatarPath'] as String?,
      monthlyPayment: _toDouble(json['monthlyPayment']),
      markupAmount: _toDouble(json['markupAmount']),
      totalAmount: _toDouble(json['totalAmount']),
      isMine: json['isMine'] as bool? ??
          json['isMyApplication'] as bool? ??
          json['isMy'] as bool? ??
          false,
      managerName: resolveManager(),
      applicationNumber: json['applicationNumber'] as String? ??
          (json['id'] != null ? '№ ${json['id']}' : null),
    );
  }
}

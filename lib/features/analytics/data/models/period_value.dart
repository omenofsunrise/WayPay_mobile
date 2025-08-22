class PeriodValue {
  final String periodName;
  final int value;

  PeriodValue({required this.periodName, required this.value});

  factory PeriodValue.fromJson(Map<String, dynamic> json) {
    return PeriodValue(
      periodName: json['periodName'] ?? '',
      value: json['value'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'periodName': periodName, 'value': value};
}

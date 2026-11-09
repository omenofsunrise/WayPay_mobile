class BlacklistPlusEntry {
  const BlacklistPlusEntry({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.document,
    required this.address,
    required this.isSwindler,
    required this.debts,
    this.birthdate,
    this.documentIssueDate,
  });

  final int id;
  final String fullName;
  final String phone;
  final String document;
  final String address;
  final bool isSwindler;
  final DateTime? birthdate;
  final DateTime? documentIssueDate;
  final List<BlacklistPlusDebt> debts;

  factory BlacklistPlusEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    final debtItems = (json['debts'] ?? json['Debts']) as List? ?? const [];
    return BlacklistPlusEntry(
      id: ((json['id'] ?? json['Id']) as num?)?.toInt() ?? 0,
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      phone: (json['phone'] ?? json['Phone'] ?? '').toString(),
      document: (json['doc'] ?? json['Doc'] ?? '').toString(),
      address: (json['address'] ?? json['Address'] ?? '').toString(),
      isSwindler: (json['isSwindler'] ?? json['IsSwindler']) as bool? ?? false,
      birthdate: parseDate(json['birthdate'] ?? json['Birthdate']),
      documentIssueDate: parseDate(
        json['docIssueDate'] ?? json['DocIssueDate'],
      ),
      debts: debtItems
          .whereType<Map>()
          .map(
            (item) =>
                BlacklistPlusDebt.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class BlacklistPlusDebt {
  const BlacklistPlusDebt({required this.paid, this.endingAt});

  final bool paid;
  final DateTime? endingAt;

  factory BlacklistPlusDebt.fromJson(Map<String, dynamic> json) {
    final date = json['debtEndingAt'] ?? json['DebtEndingAt'];
    return BlacklistPlusDebt(
      paid: (json['payed'] ?? json['Payed']) as bool? ?? false,
      endingAt: date == null ? null : DateTime.tryParse(date.toString()),
    );
  }
}

class BlacklistPlusSearchResult {
  const BlacklistPlusSearchResult({
    required this.items,
    required this.totalCount,
  });

  final List<BlacklistPlusEntry> items;
  final int totalCount;

  factory BlacklistPlusSearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] ?? json['Items']) as List? ?? const [];
    return BlacklistPlusSearchResult(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                BlacklistPlusEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      totalCount:
          ((json['totalItemsCount'] ??
                      json['TotalItemsCount'] ??
                      json['totalCount'] ??
                      json['TotalCount'])
                  as num?)
              ?.toInt() ??
          0,
    );
  }
}

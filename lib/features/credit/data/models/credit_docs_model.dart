class PaymentScheduleItem {
  final int index;
  final String date;
  final String balance;
  final String payment;
  final String? note;

  PaymentScheduleItem({
    required this.index,
    required this.date,
    required this.balance,
    required this.payment,
    this.note,
  });

  factory PaymentScheduleItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    return PaymentScheduleItem(
      index: parseInt(json['index']),
      date: json['date']?.toString() ?? '',
      balance: json['balance']?.toString() ?? '',
      payment: json['payment']?.toString() ?? '',
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'date': date,
    'balance': balance,
    'payment': payment,
    'note': note,
  };
}

class CreditDocsModel {
  final String? contractNumber;
  final String? contractDate;

  final String? clientName;
  final String? clientBirthdate;
  final String? passportSeries;
  final String? passportNumber;
  final String? docIssueDate;
  final String? clientPhone;
  final String? clientAddress;

  final String? guarantorName;
  final String? guarantorBirthdate;
  final String? guarantorPassportSeries;
  final String? guarantorPassportNumber;
  final String? guarantorDocIssueDate;
  final String? guarantorPhone;
  final String? guarantorAddress;

  final String? city;
  final String? chief;
  final String? address;
  final String? checkingAccount;
  final String? email;
  final String? inn;

  final String? lastDay;
  final String? termMonths;
  final String? totalAmount;
  final String? cleanAmount;
  final String? addAmount;
  final String? firstPayment;
  final String? restAmount;
  final String? product;

  final List<PaymentScheduleItem> paymentSchedule;

  /// Доп. поля, которых нет в модели, но могут прийти
  final Map<String, dynamic> extras;

  CreditDocsModel({
    this.contractNumber,
    this.contractDate,
    this.clientName,
    this.clientBirthdate,
    this.passportSeries,
    this.passportNumber,
    this.docIssueDate,
    this.clientPhone,
    this.clientAddress,
    this.guarantorName,
    this.guarantorBirthdate,
    this.guarantorPassportSeries,
    this.guarantorPassportNumber,
    this.guarantorDocIssueDate,
    this.guarantorPhone,
    this.guarantorAddress,
    this.city,
    this.chief,
    this.address,
    this.checkingAccount,
    this.email,
    this.inn,
    this.lastDay,
    this.termMonths,
    this.totalAmount,
    this.cleanAmount,
    this.addAmount,
    this.firstPayment,
    this.restAmount,
    this.product,
    required this.paymentSchedule,
    required this.extras,
  });

  factory CreditDocsModel.fromJson(Map<String, dynamic> j) {
    final schedule = (j['paymentSchedule'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PaymentScheduleItem.fromJson)
        .toList();

    // известные ключи
    const known = {
      'contractNumber',
      'contractDate',
      'clientName',
      'clientBirthdate',
      'passportSeries',
      'passportNumber',
      'docIssueDate',
      'clientPhone',
      'clientAddress',
      'guarantorName',
      'guarantorBirthdate',
      'guarantorPassportSeries',
      'guarantorPassportNumber',
      'guarantorDocIssueDate',
      'guarantorPhone',
      'guarantorAddress',
      'city',
      'chief',
      'address',
      'checkingAccount',
      'email',
      'inn',
      'lastDay',
      'termMonths',
      'totalAmount',
      'cleanAmount',
      'addAmount',
      'firstPayment',
      'restAmount',
      'product',
      'paymentSchedule',
    };

    final extras = <String, dynamic>{
      for (final e in j.entries)
        if (!known.contains(e.key)) e.key: e.value,
    };

    String? s(String k) => j[k]?.toString();

    return CreditDocsModel(
      contractNumber: s('contractNumber'),
      contractDate: s('contractDate'),
      clientName: s('clientName'),
      clientBirthdate: s('clientBirthdate'),
      passportSeries: s('passportSeries'),
      passportNumber: s('passportNumber'),
      docIssueDate: s('docIssueDate'),
      clientPhone: s('clientPhone'),
      clientAddress: s('clientAddress'),
      guarantorName: s('guarantorName'),
      guarantorBirthdate: s('guarantorBirthdate'),
      guarantorPassportSeries: s('guarantorPassportSeries'),
      guarantorPassportNumber: s('guarantorPassportNumber'),
      guarantorDocIssueDate: s('guarantorDocIssueDate'),
      guarantorPhone: s('guarantorPhone'),
      guarantorAddress: s('guarantorAddress'),
      city: s('city'),
      chief: s('chief'),
      address: s('address'),
      checkingAccount: s('checkingAccount'),
      email: s('email'),
      inn: s('inn'),
      lastDay: s('lastDay'),
      termMonths: s('termMonths'),
      totalAmount: s('totalAmount'),
      cleanAmount: s('cleanAmount'),
      addAmount: s('addAmount'),
      firstPayment: s('firstPayment'),
      restAmount: s('restAmount'),
      product: s('product'),
      paymentSchedule: schedule,
      extras: extras,
    );
  }
}

import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';

// credit_creation_state.dart
class CreditCreationState {
  final CreateCreditRequest creditRequest;
  final int markupType; // 0 - рубли, 1 - проценты
  final double totalAmountWithSurcharge;
  final ClientModel? selectedClient;
  final InvestorsModel? selectedInvestor;

  CreditCreationState({
    required this.creditRequest,
    this.markupType = 0,
    required this.totalAmountWithSurcharge,
    this.selectedClient,
    this.selectedInvestor,
  });

  CreditCreationState copyWith({
    CreateCreditRequest? creditRequest,
    int? markupType,
    double? totalAmountWithSurcharge,
    ClientModel? selectedClient,
    InvestorsModel? selectedInvestor,
  }) {
    return CreditCreationState(
      creditRequest: creditRequest ?? this.creditRequest,
      markupType: markupType ?? this.markupType,
      totalAmountWithSurcharge:
          totalAmountWithSurcharge ?? this.totalAmountWithSurcharge,
      selectedClient: selectedClient ?? this.selectedClient,
      selectedInvestor: selectedInvestor ?? this.selectedInvestor,
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_creation_state.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';

class CreditCreationCubit extends Cubit<CreditCreationState> {
  CreditCreationCubit()
    : super(
        CreditCreationState(
          creditRequest: CreateCreditRequest(
            clientId: null,
            name: '',
            creditTypeId: 0,
            creditTabTypeId: 0,
            guarantorClientId: 0,
            guarantor: null,
            investorId: null,
            poolId: null,
            creditDate: DateTime.now(),
            firstPayment: 0,
            termMonths: 12,
            paymentDay: 1,
            nextMonthStart: false,
            currentMonthStart: false,
            inDebt: false,
            debtComment: null,
            products: [CreditProduct(name: '', price: 0, quantity: 1)],
          ),
          markupType: 0,
          totalAmountWithSurcharge: 0,
          selectedClient: null,
          selectedInvestor: null,
          selectedCatalog: null,
          selectedCategory: null,
        ),
      );

  void updateBasicInfo({
    int? clientId,
    String? name,
    int? creditTypeId,
    int? creditTabTypeId,
    int? guarantorClientId,
    Guarantor? guarantor,
    int? investorId,
    int? poolId,
    DateTime? creditDate,
    bool? inDebt,
    String? debtComment,
    ClientModel? selectedClient,
    InvestorsModel? selectedInvestor,
    ObjectTypeModel? selectedCatalog,
    ObjectTypeModel? selectedCategory,
  }) {
    final updatedRequest = state.creditRequest.copyWith(
      clientId: clientId,
      name: name,
      creditTypeId: creditTypeId,
      creditTabTypeId: creditTabTypeId,
      guarantorClientId: guarantorClientId,
      guarantor: guarantor,
      investorId: investorId,
      poolId: poolId,
      creditDate: creditDate,
      inDebt: inDebt,
      debtComment: debtComment,
    );

    emit(
      state.copyWith(
        creditRequest: updatedRequest,
        selectedClient: selectedClient ?? state.selectedClient,
        selectedInvestor: selectedInvestor ?? state.selectedInvestor,
        selectedCatalog: selectedCatalog ?? state.selectedCatalog,
        selectedCategory: selectedCategory ?? state.selectedCategory,
      ),
    );
  }

  void updateCatalog(ObjectTypeModel? catalog) {
    emit(state.copyWith(selectedCatalog: catalog, keepCategory: true));
  }

  void updateCategory(ObjectTypeModel? category) {
    emit(state.copyWith(selectedCategory: category, keepCatalog: true));
  }

  void updatePaymentInfo({
    double? firstPayment,
    int? termMonths,
    int? paymentDay,
    bool? nextMonthStart,
    bool? currentMonthStart,
  }) {
    double adjustedFirstPayment =
        firstPayment ?? state.creditRequest.firstPayment;

    if (adjustedFirstPayment > state.totalAmountWithSurcharge) {
      adjustedFirstPayment = state.totalAmountWithSurcharge;
    }

    final updatedRequest = state.creditRequest.copyWith(
      firstPayment: adjustedFirstPayment,
      termMonths: termMonths,
      paymentDay: paymentDay,
      nextMonthStart: nextMonthStart,
      currentMonthStart: currentMonthStart,
    );

    emit(state.copyWith(creditRequest: updatedRequest));
  }

  void updateProducts(List<CreditProduct> products) {
    final updatedProducts = _recalculateSurchargeAmounts(
      products,
      state.markupType,
    );
    final updatedRequest = state.creditRequest.copyWith(
      products: updatedProducts,
    );
    final totalAmount = _calculateTotalAmountWithSurcharge(updatedProducts);

    double firstPayment = updatedRequest.firstPayment;
    if (firstPayment > totalAmount) {
      firstPayment = totalAmount;
      updatedRequest.firstPayment = firstPayment;
    }

    emit(
      state.copyWith(
        creditRequest: updatedRequest,
        totalAmountWithSurcharge: totalAmount,
      ),
    );
  }

  void updateMarkupType(int markupType) {
    final updatedProducts = _recalculateSurchargeAmounts(
      state.creditRequest.products,
      markupType,
    );

    final updatedRequest = state.creditRequest.copyWith(
      products: updatedProducts,
    );
    final totalAmount = _calculateTotalAmountWithSurcharge(updatedProducts);

    double firstPayment = updatedRequest.firstPayment;
    if (firstPayment > totalAmount) {
      firstPayment = totalAmount;
      updatedRequest.firstPayment = firstPayment;
    }

    emit(
      state.copyWith(
        markupType: markupType,
        creditRequest: updatedRequest,
        totalAmountWithSurcharge: totalAmount,
      ),
    );
  }

  void updateStartMonthOption(bool isCurrentMonth) {
    final updatedRequest = state.creditRequest.copyWith(
      currentMonthStart: isCurrentMonth,
      nextMonthStart: !isCurrentMonth,
    );

    emit(state.copyWith(creditRequest: updatedRequest));
  }

  List<CreditProduct> _recalculateSurchargeAmounts(
    List<CreditProduct> products,
    int markupType,
  ) {
    return products.map((product) {
      double surchargeAmount = 0;

      if (markupType == 0) {
        surchargeAmount = product.surcharge ?? 0;
      } else {
        final surchargePercent = product.surcharge ?? 0;
        surchargeAmount = (product.price * surchargePercent) / 100;
      }

      return product.copyWith(surchargeAmount: surchargeAmount);
    }).toList();
  }

  void updateFirstPaymentByAmount(double amount) {
    final totalAmount = state.totalAmountWithSurcharge;
    double adjustedAmount = amount;

    if (adjustedAmount > totalAmount) {
      adjustedAmount = totalAmount;
    }

    final updatedRequest = state.creditRequest.copyWith(
      firstPayment: adjustedAmount,
    );

    emit(state.copyWith(creditRequest: updatedRequest));
  }

  void updateFirstPaymentByPercent(int percent) {
    final totalAmount = state.totalAmountWithSurcharge;
    double amount = 0;

    if (percent > 0 && totalAmount > 0) {
      amount = (totalAmount * percent / 100);
      amount = amount.floorToDouble();
    }

    if (amount > totalAmount) {
      amount = totalAmount;
    }

    final updatedRequest = state.creditRequest.copyWith(firstPayment: amount);

    emit(state.copyWith(creditRequest: updatedRequest));
  }

  void updateFirstPayment(double amount) {
    final totalAmount = state.totalAmountWithSurcharge;
    double adjustedAmount = amount;

    if (adjustedAmount > totalAmount) {
      adjustedAmount = totalAmount;
    }

    adjustedAmount = adjustedAmount.floorToDouble();

    final updatedRequest = state.creditRequest.copyWith(
      firstPayment: adjustedAmount,
    );

    emit(state.copyWith(creditRequest: updatedRequest));
  }

  double _calculateTotalAmountWithSurcharge(List<CreditProduct> products) {
    final total = products.fold(0.0, (sum, product) {
      final basePrice = product.price * product.quantity;
      final surchargeAmount = product.surchargeAmount ?? 0;
      return sum + basePrice + surchargeAmount;
    });

    return _roundUpToFifty(total);
  }

  double _roundUpToFifty(double amount) {
    return (amount / 50).ceil() * 50.0;
  }
}

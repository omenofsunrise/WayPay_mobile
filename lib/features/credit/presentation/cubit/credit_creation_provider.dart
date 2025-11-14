import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/features/credit/data/models/new_credit_model.dart';

class CreditCreationCubit extends Cubit<CreateCreditRequest> {
  CreditCreationCubit()
    : super(
        CreateCreditRequest(
          name: '',
          creditTypeId: 0,
          creditTabTypeId: 0,
          guarantorClientId: 0,
          creditDate: DateTime.now(),
          firstPayment: 0,
          termMonths: 0,
          paymentDay: 1,
          nextMonthStart: false,
          inDebt: false,
          products: [],
        ),
      );

  void updateBasicInfo({
    String? name,
    int? creditTypeId,
    int? creditTabTypeId,
    int? clientId,
    DateTime? creditDate,
  }) {
    emit(
      state.copyWith(
        name: name,
        creditTypeId: creditTypeId,
        creditTabTypeId: creditTabTypeId,
        clientId: clientId,
        creditDate: creditDate,
      ),
    );
  }

  void updatePaymentInfo({
    double? firstPayment,
    int? termMonths,
    int? paymentDay,
    bool? nextMonthStart,
    bool? inDebt,
    String? debtComment,
  }) {
    emit(
      state.copyWith(
        firstPayment: firstPayment,
        termMonths: termMonths,
        paymentDay: paymentDay,
        nextMonthStart: nextMonthStart,
        inDebt: inDebt,
        debtComment: debtComment,
      ),
    );
  }

  void updateGuarantorInfo({int? guarantorClientId, Guarantor? guarantor}) {
    emit(
      state.copyWith(
        guarantorClientId: guarantorClientId,
        guarantor: guarantor,
      ),
    );
  }

  void updateProducts(List<CreditProduct> products) {
    emit(state.copyWith(products: products));
  }

  void addProduct(CreditProduct product) {
    final newProducts = List<CreditProduct>.from(state.products)..add(product);
    emit(state.copyWith(products: newProducts));
  }

  void removeProduct(int index) {
    final newProducts = List<CreditProduct>.from(state.products)
      ..removeAt(index);
    emit(state.copyWith(products: newProducts));
  }

  void clear() {
    emit(
      CreateCreditRequest(
        name: '',
        creditTypeId: 0,
        creditTabTypeId: 0,
        guarantorClientId: 0,
        creditDate: DateTime.now(),
        firstPayment: 0,
        termMonths: 0,
        paymentDay: 1,
        nextMonthStart: false,
        inDebt: false,
        products: [],
      ),
    );
  }
}

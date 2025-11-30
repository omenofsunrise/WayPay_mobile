import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_creation_state.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';

class CreditCreationCubit extends Cubit<CreditCreationState> {
  final CreditRemoteDataSource _dataSource = getIt<CreditRemoteDataSource>();
  Timer? _debounceTimer;
  CreditCreationCubit()
    : super(
        CreditCreationState(
          creditRequest: _initialRequest(),
          markupType: 0,
          totalAmountWithSurcharge: 0,
          selectedClient: null,
          selectedInvestor: null,
          selectedCatalog: null,
          selectedCategory: null,
          schedulePreview: [],
          schedulePreviewLoading: false,
          schedulePreviewError: null,
        ),
      ) {
    _initMarkupType();
  }

  static CreateCreditRequest _initialRequest() {
    final now = DateTime.now();
    return CreateCreditRequest(
      clientId: null,
      name: '',
      creditTypeId: 0,
      creditTabTypeId: 0,
      guarantorClientId: 0,
      guarantor: null,
      investorId: null,
      poolId: null,
      creditDate: now,
      firstPayment: 0,
      termMonths: 0,
      paymentDay: now.add(const Duration(days: 1)).day,
      nextMonthStart: false,
      currentMonthStart: false,
      inDebt: false,
      debtComment: null,
      products: [CreditProduct(name: '', price: 0, quantity: 1)],
    );
  }

  int _getNextPaymentDay(DateTime date) {
    return date.add(const Duration(days: 1)).day;
  }

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
    CreateCreditRequest updatedRequest = state.creditRequest.copyWith(
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

    if (creditDate != null) {
      final nextDay = _getNextPaymentDay(creditDate);
      updatedRequest = updatedRequest.copyWith(paymentDay: nextDay);
    }

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
    final updatedRequest = state.creditRequest.copyWith(
      creditTabTypeId: catalog?.id,
    );
    emit(
      state.copyWith(
        creditRequest: updatedRequest,
        selectedCatalog: catalog,
        keepCategory: true,
      ),
    );
  }

  void updateCategory(ObjectTypeModel? category) {
    final updatedRequest = state.creditRequest.copyWith(
      creditTypeId: category?.id,
    );
    emit(
      state.copyWith(
        creditRequest: updatedRequest,
        selectedCategory: category,
        keepCatalog: true,
      ),
    );
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

    _loadSchedulePreviewDebounced();
  }

  Future<void> loadSchedulePreview() async {
    if (state.totalAmountWithSurcharge <= 0 ||
        state.creditRequest.termMonths <= 0) {
      return;
    }

    emit(
      state.copyWith(schedulePreviewLoading: true, schedulePreviewError: null),
    );

    try {
      final preview = await _dataSource.getSchedulePreview(
        totalAmount: state.totalAmountWithSurcharge,
        firstPayment: state.creditRequest.firstPayment,
        termMonths: state.creditRequest.termMonths,
        paymentDay: state.creditRequest.paymentDay,
        currentMonthStart: state.creditRequest.currentMonthStart,
        nextMonthStart: state.creditRequest.nextMonthStart,
      );

      emit(
        state.copyWith(
          schedulePreview: preview,
          schedulePreviewLoading: false,
          schedulePreviewError: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          schedulePreviewLoading: false,
          schedulePreviewError: 'Ошибка загрузки графика платежей: $e',
        ),
      );
    }
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

    _loadSchedulePreviewDebounced();
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

    _loadSchedulePreviewDebounced();
    _saveMarkupType(markupType);
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
        final surchargePercent = product.surcharge ?? 0;
        surchargeAmount = (product.price * surchargePercent) / 100;
      } else {
        surchargeAmount = product.surcharge ?? 0;
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

    _loadSchedulePreviewDebounced();
  }

  void _loadSchedulePreviewDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadSchedulePreview();
    });
  }

  Future<void> _loadSchedulePreview() async {
    if (state.totalAmountWithSurcharge <= 0 ||
        state.creditRequest.termMonths <= 0) {
      return;
    }

    final currentState = state;

    emit(
      currentState.copyWith(
        schedulePreviewLoading: true,
        schedulePreviewError: null,
      ),
    );

    try {
      final preview = await _dataSource.getSchedulePreview(
        totalAmount: state.totalAmountWithSurcharge,
        firstPayment: state.creditRequest.firstPayment,
        termMonths: state.creditRequest.termMonths,
        paymentDay: state.creditRequest.paymentDay,
        currentMonthStart: state.creditRequest.currentMonthStart,
        nextMonthStart: state.creditRequest.nextMonthStart,
      );

      emit(
        state.copyWith(
          schedulePreview: preview,
          schedulePreviewLoading: false,
          schedulePreviewError: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          schedulePreviewLoading: false,
          schedulePreviewError: 'Ошибка загрузки графика платежей: $e',
        ),
      );
    }
  }

  void refreshSchedulePreview() {
    _loadSchedulePreview();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future createCredit() async {
    try {
      if (state.creditRequest.clientId == null) {
        throw Exception('Не выбран клиент');
      }

      if (state.creditRequest.products.isEmpty) {
        throw Exception('Не добавлены товары');
      }

      for (final product in state.creditRequest.products) {
        if (product.name.isEmpty) {
          throw Exception('Название товара не может быть пустым');
        }
        if (product.price <= 0) {
          throw Exception('Цена товара должна быть больше 0');
        }
        if (product.quantity <= 0) {
          throw Exception('Количество товара должно быть больше 0');
        }
      }

      if (state.totalAmountWithSurcharge <= 0) {
        throw Exception('Общая сумма должна быть больше 0');
      }

      if (state.creditRequest.firstPayment < 0) {
        throw Exception('Первоначальный платеж не может быть отрицательным');
      }

      if (state.creditRequest.firstPayment > state.totalAmountWithSurcharge) {
        throw Exception('Первоначальный платеж не может превышать общую сумму');
      }

      if (state.creditRequest.termMonths <= 0) {
        throw Exception('Срок договора должен быть больше 0 месяцев');
      }

      if (state.creditRequest.paymentDay < 1 ||
          state.creditRequest.paymentDay > 31) {
        throw Exception('День платежа должен быть от 1 до 31');
      }

      Guarantor? guarantor;
      if (state.creditRequest.guarantor != null) {
        final guar = state.creditRequest.guarantor!;
        if (guar.fullName.isEmpty || guar.phone.isEmpty) {
          throw Exception('Заполните ФИО и телефон гаранта');
        }
        guarantor = guar;
      }

      final createRequest = CreateCreditRequest(
        clientId: state.creditRequest.clientId,
        name: state.creditRequest.name.trim(),
        creditTypeId: state.creditRequest.creditTypeId,
        creditTabTypeId: state.creditRequest.creditTabTypeId,
        guarantorClientId: state.creditRequest.guarantorClientId,
        guarantor: guarantor,
        investorId: state.creditRequest.investorId,
        poolId: state.creditRequest.poolId,
        creditDate: state.creditRequest.creditDate,
        firstPayment: state.creditRequest.firstPayment,
        termMonths: state.creditRequest.termMonths,
        paymentDay: state.creditRequest.paymentDay,
        nextMonthStart: state.creditRequest.nextMonthStart,
        currentMonthStart: state.creditRequest.currentMonthStart,
        inDebt: state.creditRequest.inDebt,
        debtComment: state.creditRequest.debtComment?.trim(),
        products: state.creditRequest.products.map((product) {
          return CreditProduct(
            name: product.name.trim(),
            price: product.price,
            quantity: product.quantity,
            surcharge: product.surcharge,
            surchargeAmount: product.surchargeAmount,
          );
        }).toList(),
      );

      final requestJson = jsonEncode(createRequest.toJson());
      print('Create credit payload: $requestJson');

      await _dataSource.createCredit(createRequest);

      await _resetState();

      return;
    } catch (e) {
      print('Ошибка создания договора: $e');
      rethrow;
    }
  }

  Future<void> _resetState() async {
    final savedMarkupType = await _loadMarkupType();
    emit(
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
          termMonths: 0,
          paymentDay: 1,
          nextMonthStart: false,
          currentMonthStart: false,
          inDebt: false,
          debtComment: null,
          products: [CreditProduct(name: '', price: 0, quantity: 1)],
        ),
        markupType: savedMarkupType,
        totalAmountWithSurcharge: 0,
        selectedClient: null,
        selectedInvestor: null,
        selectedCatalog: null,
        selectedCategory: null,
        schedulePreview: [],
        schedulePreviewLoading: false,
        schedulePreviewError: null,
      ),
    );
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

  Future<void> _saveMarkupType(int markupType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('credit_markup_type', markupType);
  }

  Future<int> _loadMarkupType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('credit_markup_type') ?? 0;
  }

  void _initMarkupType() {
    Future.microtask(() async {
      final saved = await _loadMarkupType();
      if (!isClosed && saved != state.markupType) {
        emit(state.copyWith(markupType: saved));
      }
    });
  }
}

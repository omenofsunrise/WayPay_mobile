import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_creation_state.dart';
import 'package:waypay_mobile/features/credit/data/models/new_credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/cubit/credit_creation_provider.dart';
import 'package:waypay_mobile/features/credit/presentation/screens/create_credit/custom_page_transitions.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'step1_details_content.dart';
import 'step2_products_content.dart';
import 'step3_schedules_content.dart';

class NewCreditCreationScreen extends StatefulWidget {
  const NewCreditCreationScreen({super.key});

  @override
  State<NewCreditCreationScreen> createState() =>
      _NewCreditCreationScreenState();
}

class _NewCreditCreationScreenState extends State<NewCreditCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstPaymentController = TextEditingController();
  final _termMonthsController = TextEditingController();
  final _paymentDayController = TextEditingController();
  final _firstPaymentPercentController = TextEditingController();
  final _firstPaymentAmountController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeForm();
  }

  void _initializeForm() {
    final state = context.read<CreditCreationCubit>().state;
    final creditRequest = state.creditRequest;

    _firstPaymentController.text = creditRequest.firstPayment.toString();
    _termMonthsController.text = creditRequest.termMonths.toString();
    _paymentDayController.text = creditRequest.paymentDay.toString();

    _updateFirstPaymentFields(
      creditRequest.firstPayment,
      state.totalAmountWithSurcharge,
    );
  }

  void _updateFirstPaymentFields(double firstPayment, double totalAmount) {
    if (firstPayment > 0 && totalAmount > 0) {
      final percent = (firstPayment / totalAmount * 100);
      _firstPaymentPercentController.text = percent.toStringAsFixed(2);
      _firstPaymentAmountController.text = firstPayment.toStringAsFixed(2);
    } else {
      _firstPaymentPercentController.text = '';
      _firstPaymentAmountController.text = '';
    }
  }

  void _updateFirstPayment(double amount) {
    context.read<CreditCreationCubit>().updatePaymentInfo(firstPayment: amount);
  }

  void _updateTermMonths(int termMonths) {
    context.read<CreditCreationCubit>().updatePaymentInfo(
      termMonths: termMonths,
    );
  }

  void _updateNextMonthStart(bool value) {
    context.read<CreditCreationCubit>().updatePaymentInfo(
      nextMonthStart: value,
    );
  }

  void _updatePaymentDay(int day) {
    context.read<CreditCreationCubit>().updatePaymentInfo(paymentDay: day);
  }

  void _updateMarkupType(int markupType) {
    context.read<CreditCreationCubit>().updateMarkupType(markupType);
  }

  void _updateProducts(List<CreditProduct> products) {
    context.read<CreditCreationCubit>().updateProducts(products);
  }

  int get _currentStep {
    final location = GoRouterState.of(context).uri.toString();

    if (location == Routes.newCreditDetailsScreen.toPath) {
      return 1;
    } else if (location == Routes.newCreditProductsScreen.toPath) {
      return 2;
    } else if (location == Routes.newCreditSchedulesScreen.toPath) {
      return 3;
    }
    return 1;
  }

  String? get _nextRoute {
    final location = GoRouterState.of(context).uri.toString();

    if (location == Routes.newCreditDetailsScreen.toPath) {
      return Routes.newCreditProductsScreen.toPath;
    } else if (location == Routes.newCreditProductsScreen.toPath) {
      return Routes.newCreditSchedulesScreen.toPath;
    } else if (location == Routes.newCreditSchedulesScreen.toPath) {
      return null;
    }
    return Routes.newCreditProductsScreen.toPath;
  }

  String? get _previousRoute {
    final location = GoRouterState.of(context).uri.toString();

    if (location == Routes.newCreditProductsScreen.toPath) {
      return Routes.newCreditDetailsScreen.toPath;
    } else if (location == Routes.newCreditSchedulesScreen.toPath) {
      return Routes.newCreditProductsScreen.toPath;
    }
    return null;
  }

  void _handleBackButton() {
    if (_previousRoute != null) {
      _navigateBack();
    } else {
      context.go(Routes.creditsScreen.toPath);
    }
  }

  void _navigateBack() {
    final page = SlideRightTransition(child: NewCreditCreationScreen());
    context.pushReplacement(_previousRoute!, extra: page);
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      if (_nextRoute != null) {
        context.go(_nextRoute!);
      } else {
        _finishCreditCreation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(AppColors.background),
        title: const Text(
          'Новый договор',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Color(AppColors.grey),
          onPressed: _handleBackButton,
        ),
      ),
      body: BlocListener<CreditCreationCubit, CreditCreationState>(
        listener: (context, state) {
          final creditRequest = state.creditRequest;

          if (_firstPaymentController.text.isEmpty ||
              double.parse(_firstPaymentController.text) !=
                  creditRequest.firstPayment) {
            _firstPaymentController.text = creditRequest.firstPayment
                .toString();
          }

          if (_termMonthsController.text.isEmpty ||
              int.parse(_termMonthsController.text) !=
                  creditRequest.termMonths) {
            _termMonthsController.text = creditRequest.termMonths.toString();
          }

          if (_paymentDayController.text.isEmpty ||
              int.parse(_paymentDayController.text) !=
                  creditRequest.paymentDay) {
            _paymentDayController.text = creditRequest.paymentDay.toString();
          }

          _updateFirstPaymentFields(
            creditRequest.firstPayment,
            state.totalAmountWithSurcharge,
          );
        },
        child: Container(
          color: Color(AppColors.background),
          child: Column(
            children: [
              _buildStepperWidget(_currentStep, 3),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: _buildStepContent(),
                          ),
                        ),
                        _buildBottomButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    final location = GoRouterState.of(context).uri.toString();

    if (location == Routes.newCreditDetailsScreen.toPath) {
      return Step1DetailsContent(
        firstPaymentController: _firstPaymentController,
        termMonthsController: _termMonthsController,
        paymentDayController: _paymentDayController,
      );
    } else if (location == Routes.newCreditProductsScreen.toPath) {
      return BlocBuilder<CreditCreationCubit, CreditCreationState>(
        builder: (context, state) {
          return Step2ProductsContent(
            products: state.creditRequest.products,
            onProductsChanged: _updateProducts,
            markupType: state.markupType,
            onMarkupTypeChanged: _updateMarkupType,
            totalAmount: state.totalAmountWithSurcharge,
          );
        },
      );
    } else if (location == Routes.newCreditSchedulesScreen.toPath) {
      return BlocBuilder<CreditCreationCubit, CreditCreationState>(
        builder: (context, state) {
          return Step3SchedulesContent(
            nextMonthStart: state.creditRequest.nextMonthStart,
            onNextMonthStartChanged: _updateNextMonthStart,
            firstPayment: state.creditRequest.firstPayment,
            termMonths: state.creditRequest.termMonths,
            paymentDay: state.creditRequest.paymentDay,
            onPaymentDayChanged: _updatePaymentDay,
            onFirstPaymentChanged: _updateFirstPayment,
            onTermMonthsChanged: _updateTermMonths,
            totalAmount: state.totalAmountWithSurcharge,
          );
        },
      );
    }
    return Container();
  }

  Widget _buildStepperWidget(int currentStep, int totalSteps) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Шаг $currentStep из $totalSteps',
            style: TextStyle(
              color: Color(AppColors.primary),
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      child: Row(
        children: [
          if (_previousRoute != null) ...[
            Expanded(
              child: DefaultButton(
                text: 'Назад',
                onPressed: _navigateBack,
                isGreen: false,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: DefaultButton(
              text: _currentStep == 3 ? 'Завершить' : 'Далее',
              onPressed: _handleContinue,
              isGreen: true,
            ),
          ),
        ],
      ),
    );
  }

  void _finishCreditCreation() {
    print('Завершение создания кредита');
    context.go(Routes.creditsScreen.toPath);
  }

  @override
  void dispose() {
    _firstPaymentController.dispose();
    _termMonthsController.dispose();
    _paymentDayController.dispose();
    _firstPaymentPercentController.dispose();
    _firstPaymentAmountController.dispose();
    super.dispose();
  }
}

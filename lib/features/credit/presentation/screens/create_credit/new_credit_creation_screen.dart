import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
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
  final _firstPaymentPercentController = TextEditingController();
  final _firstPaymentAmountController = TextEditingController();
  String? _inlineMessage;
  bool _inlineMessageIsError = false;

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

  void _updateTermMonths(int termMonths) {
    context.read<CreditCreationCubit>().updatePaymentInfo(
      termMonths: termMonths,
    );
  }

  void _updateStartPaymentDay(DateTime date) {
    context.read<CreditCreationCubit>().updatePaymentInfo(
      startPaymentDay: date,
    );
  }

  void _updateMarkupType(int markupType) {
    context.read<CreditCreationCubit>().updateMarkupType(markupType);
  }

  void _updateProducts(List<CreditProduct> products) {
    context.read<CreditCreationCubit>().updateProducts(products);
  }

  void _showInlineMessage({required String message, required bool isError}) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = message;
      _inlineMessageIsError = isError;
    });
  }

  void _clearInlineMessage() {
    if (_inlineMessage == null) return;
    setState(() {
      _inlineMessage = null;
    });
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
      context.goNamed(Routes.creditsScreen.toName);
    }
  }

  void _navigateBack() {
    final page = SlideRightTransition(child: NewCreditCreationScreen());
    context.pushReplacement(_previousRoute!, extra: page);
  }

  void _handleContinue() {
    final cubit = context.read<CreditCreationCubit>();
    final state = cubit.state;
    _clearInlineMessage();
    if (!_isStepValid(state)) return;
    if (_formKey.currentState!.validate()) {
      cubit.logCurrentState('STEP_${_currentStep}');
      if (_currentStep == 3) {
        final productsJson = cubit.state.creditRequest.products
            .map((p) => p.toJson())
            .toList();
        debugPrint('[STEP_3_PRODUCTS] $productsJson');
      }
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
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: BlocListener<CreditCreationCubit, CreditCreationState>(
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
                _termMonthsController.text = creditRequest.termMonths
                    .toString();
              }

              _updateFirstPaymentFields(
                creditRequest.firstPayment,
                state.totalAmountWithSurcharge,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Header(
                  title: 'Новый договор',
                  showBackButton: false,
                  showNotifications: false,
                  showAvatar: false,
                  onBackPressed: _handleBackButton,
                ),
                const SizedBox(height: 12),
                _buildStepperWidget(_currentStep, 3),
                const SizedBox(height: 16),
                Expanded(
                  child: Form(
                    key: _formKey,
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
              ],
            ),
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
            firstPayment: state.creditRequest.firstPayment,
            termMonths: state.creditRequest.termMonths,
            startPaymentDay: state.creditRequest.startPaymentDay,
            onStartPaymentDayChanged: _updateStartPaymentDay,
            onFirstPaymentChanged: (amount) {
              context.read<CreditCreationCubit>().updateFirstPayment(amount);
            },
            onTermMonthsChanged: _updateTermMonths,
            totalAmount: state.totalAmountWithSurcharge,
          );
        },
      );
    }
    return Container();
  }

  Widget _buildStepperWidget(int currentStep, int totalSteps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'Шаг $currentStep из $totalSteps',
          style: const TextStyle(
            color: Color(AppColors.primary),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final bool hasPrevious = _previousRoute != null;
    final String leftButtonText = hasPrevious ? 'Назад' : 'Отменить';
    final VoidCallback leftAction = hasPrevious
        ? _navigateBack
        : () => context.goNamed(Routes.creditsScreen.toName);

    return BlocBuilder<CreditCreationCubit, CreditCreationState>(
      builder: (context, state) {
        final canProceed = _isStepValid(state);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_inlineMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _inlineMessageIsError
                      ? const Color(0x14FF3B30)
                      : const Color(0x1420A39F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _inlineMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _inlineMessageIsError
                        ? const Color(AppColors.red)
                        : const Color(AppColors.black),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: DefaultButton(
                    text: leftButtonText,
                    onPressed: leftAction,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultButton(
                    text: _currentStep == 3 ? 'Создать' : 'Далее',
                    onPressed: canProceed ? _handleContinue : null,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  bool _isStepValid(CreditCreationState state) {
    switch (_currentStep) {
      case 1:
        return _isStep1Valid(state);
      case 2:
        return _isStep2Valid(state);
      case 3:
        return _isStep3Valid(state);
      default:
        return false;
    }
  }

  bool _isStep1Valid(CreditCreationState state) {
    final request = state.creditRequest;
    final hasClient = state.selectedClient != null || request.clientId != null;
    final hasInvestorOrDebt =
        request.inDebt ||
        state.selectedInvestor != null ||
        request.investorId != null ||
        request.poolId != null;
    return hasClient && hasInvestorOrDebt;
  }

  bool _isStep2Valid(CreditCreationState state) {
    final products = state.creditRequest.products;
    if (products.isEmpty) return false;
    return products.every(
      (product) =>
          product.name.trim().isNotEmpty &&
          product.price > 0 &&
          product.quantity > 0,
    );
  }

  bool _isStep3Valid(CreditCreationState state) {
    final request = state.creditRequest;
    final hasTerm = request.termMonths > 0;
    final hasAmount = state.totalAmountWithSurcharge > 0;
    return hasTerm && hasAmount;
  }

  void _finishCreditCreation() async {
    final cubit = context.read<CreditCreationCubit>();

    try {
      cubit.logCurrentState('CREATE_ATTEMPT');
      final productsJson = cubit.state.creditRequest.products
          .map((p) => p.toJson())
          .toList();
      debugPrint('[CREATE_ATTEMPT_PRODUCTS] $productsJson');
      await cubit.createCredit();

      if (!mounted) return;
      GoRouter.of(context).goNamed(Routes.creditsScreen.toName);

      _showInlineMessage(message: 'Договор успешно создан', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showInlineMessage(message: _extractReadableError(e), isError: true);
    }
  }

  String _extractReadableError(Object error) {
    final raw = error.toString();
    const prefix = 'Exception:';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length).trim();
    }
    return raw;
  }

  @override
  void dispose() {
    _firstPaymentController.dispose();
    _termMonthsController.dispose();
    _firstPaymentPercentController.dispose();
    _firstPaymentAmountController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/widgets/buttons/default_button.dart';
import 'package:waypay/features/credit/data/models/new_credit_model.dart';
import 'package:waypay/features/credit/presentation/cubit/credit_creation_provider.dart';
import 'package:waypay/routes/routes.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeForm();
  }

  void _initializeForm() {
    final state = context.read<CreditCreationCubit>().state;
    _firstPaymentController.text = state.firstPayment.toString();
    _termMonthsController.text = state.termMonths.toString();
    _paymentDayController.text = state.paymentDay.toString();
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
    // Если есть предыдущий шаг, переходим на него
    if (_previousRoute != null) {
      context.go(_previousRoute!);
    } else {
      // Если это первый шаг, выходим из экрана создания кредита
      context.go(Routes.creditsScreen.toPath);
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
          onPressed: _handleBackButton, // Используем нашу функцию
        ),
      ),
      body: BlocListener<CreditCreationCubit, CreateCreditRequest>(
        listener: (context, state) {
          if (_firstPaymentController.text.isEmpty) {
            _firstPaymentController.text = state.firstPayment.toString();
          }
          if (_termMonthsController.text.isEmpty) {
            _termMonthsController.text = state.termMonths.toString();
          }
          if (_paymentDayController.text.isEmpty) {
            _paymentDayController.text = state.paymentDay.toString();
          }
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
      return const Step2ProductsContent();
    } else if (location == Routes.newCreditSchedulesScreen.toPath) {
      return const Step3SchedulesContent();
    }
    return Step1DetailsContent(
      firstPaymentController: _firstPaymentController,
      termMonthsController: _termMonthsController,
      paymentDayController: _paymentDayController,
    );
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
              fontWeight: FontWeight.bold,
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
                onPressed: () => context.go(_previousRoute!),
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

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      if (_nextRoute != null) {
        context.go(_nextRoute!);
      } else {
        _finishCreditCreation();
      }
    }
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
    super.dispose();
  }
}

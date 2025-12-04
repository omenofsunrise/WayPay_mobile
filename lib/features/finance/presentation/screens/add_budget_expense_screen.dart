import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';
import 'package:waypay_mobile/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay_mobile/features/finance/data/models/create_budget_outcome_dto.dart';
import 'package:intl/intl.dart';

class AddBudgetExpenseScreen extends StatefulWidget {
  const AddBudgetExpenseScreen({super.key});

  @override
  State<AddBudgetExpenseScreen> createState() =>
      _AddBudgetExpenseScreenState();
}

class _AddBudgetExpenseScreenState extends State<AddBudgetExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  bool _isFormatting = false;
  bool _isSaving = false;
  String? _amountError;

  bool get _canSubmit =>
      !_isSaving && _getAmountValue() > 0 && _commentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_formatAmountInput);
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatAmountInput);
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _formatAmountInput() {
    if (_isFormatting) return;
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _isFormatting = true;
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _isFormatting = false;
      return;
    }
    final value = double.tryParse(digits) ?? 0;
    final formatted = _formatInput(value);
    _isFormatting = true;
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormatting = false;
    if (_amountError != null) {
      setState(() => _amountError = null);
    } else {
      setState(() {});
    }
  }

  double _getAmountValue() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return double.parse(digits);
  }

  Future<void> _submit() async {
    final amount = _getAmountValue();
    if (amount <= 0) {
      setState(() => _amountError = 'Введите корректную сумму');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await getIt<BudgetRemoteDataSource>().createBudgetOutcome(
        CreateBudgetOutcomeDto(
          amount: amount,
          comment: _commentController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Header(
                title: 'Добавить расход',
                showBackButton: true,
                showNotifications: false,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ModalTextField(
                      controller: _amountController,
                      label: 'Введите сумму',
                      hintText: 'Введите сумму',
                      keyboardType: TextInputType.number,
                      errorText: _amountError,
                    ),
                    const SizedBox(height: 12),
                    ModalTextField(
                      controller: _commentController,
                      label: 'Введите комментарий',
                      hintText: 'Введите комментарий',
                      minLines: 4,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: DefaultButton(
                            text: 'Отменить',
                            color: const Color(0xFFB8BEC8),
                            textColor: const Color(AppColors.black),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DefaultButton(
                            text: 'Применить',
                            onPressed: _canSubmit ? _submit : null,
                            isGreen: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.decimalPattern('ru_RU');
    return formatter.format(value).replaceAll('.', ' ');
  }

  String _formatInput(double value) => _formatCurrency(value);
}

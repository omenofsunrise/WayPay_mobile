import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/finance/data/data_source/budget_remote_data_source.dart';
import 'package:waypay_mobile/features/finance/data/models/create_budget_income_dto.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investor_pool_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_picker_modal.dart';

class AddBudgetIncomeScreen extends StatefulWidget {
  const AddBudgetIncomeScreen({super.key});

  @override
  State<AddBudgetIncomeScreen> createState() => _AddBudgetIncomeScreenState();
}

class _AddBudgetIncomeScreenState extends State<AddBudgetIncomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _investorController = TextEditingController();
  final TextEditingController _companyAmountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _investorAmountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _companyShareController = TextEditingController(
    text: '100',
  );
  final TextEditingController _investorShareController = TextEditingController(
    text: '0',
  );
  final TextEditingController _commentController = TextEditingController();
  bool _isFormattingAmount = false;

  InvestorsModel? _selectedInvestor;
  double _companyShare = 100;
  bool _isSaving = false;
  String? _amountError;
  String? _investorError;
  bool _distributionEnabled = false;
  bool get _canSubmit =>
      !_isSaving &&
      _getTotalAmount() > 0 &&
      _selectedInvestor != null &&
      _commentController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_handleAmountChange);
    _commentController.addListener(_handleCommentChange);
    _updateDistributionAvailability();
    _companyAmountController.text = _formatCurrencyValue(0);
    _investorAmountController.text = _formatCurrencyValue(0);
  }

  @override
  void dispose() {
    _amountController.removeListener(_handleAmountChange);
    _amountController.dispose();
    _investorController.dispose();
    _companyAmountController.dispose();
    _investorAmountController.dispose();
    _companyShareController.dispose();
    _investorShareController.dispose();
    _commentController
      ..removeListener(_handleCommentChange)
      ..dispose();
    super.dispose();
  }

  void _updateSharesFromSlider(double value) {
    setState(() {
      _companyShare = value;
      final company = value.round();
      final investor = (100 - value).round();
      _companyShareController.text = company.toString();
      _investorShareController.text = investor.toString();
      _updateAmountsFromPercent(company.toDouble(), investor.toDouble());
    });
  }

  Future<void> _openInvestorPicker() async {
    final selected = await showModalBottomSheet<InvestorPickerResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => InvestorsBloc()),
          BlocProvider(create: (_) => InvestorPoolBloc()),
        ],
        child: const InvestorPickerModal(
          includeInvestor: true,
          includePool: false,
          title: 'Выберите инвестора',
        ),
      ),
    );

    if (selected?.investor != null) {
      final investor = selected!.investor!;
      setState(() {
        _selectedInvestor = investor;
        _investorController.text = investor.nickname;
        _investorError = null;
      });
    }
  }

  Widget _buildCashboxInfo() {
    final investor = _selectedInvestor;
    final available = (investor?.cashbox ?? investor?.balance)?.toDouble();
    if (available == null) return const SizedBox.shrink();
    final entered = _getTotalAmount();
    final remaining = (available - entered).clamp(0, available).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Доступно для вывода:'),
              Text(
                _formatMoney(available),
                style: AppStyle.manrope(
                  size: 16,
                  weight: FontWeight.w600,
                  color: const Color(AppColors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Можно вывести ещё:'),
              Text(
                _formatMoney(remaining),
                style: AppStyle.manrope(
                  size: 16,
                  weight: FontWeight.w600,
                  color: const Color(AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _amountError = null;
      _investorError = null;
    });

    final amountValue = _getTotalAmount();
    if (amountValue == null || amountValue <= 0) {
      setState(() => _amountError = 'Введите корректную сумму');
      return;
    }
    if (_selectedInvestor == null) {
      setState(() => _investorError = 'Выберите инвестора');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await getIt<BudgetRemoteDataSource>().createBudgetIncome(
        CreateBudgetIncomeDto(
          amount: amountValue,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          investorId: _selectedInvestor!.id,
          companyShare: _companyShare.round(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
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
                title: 'Добавить приход',
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
                      controller: _investorController,
                      label: 'Выберите инвестора',
                      hintText: 'Выберите инвестора',
                      readOnly: true,
                      onTap: _openInvestorPicker,
                      errorText: _investorError,
                    ),
                    const SizedBox(height: 12),
                    _buildCashboxInfo(),
                    const SizedBox(height: 20),
                    Text(
                      'Распределение',
                      style: AppStyle.manrope(
                        size: 16,
                        weight: FontWeight.w600,
                        color: const Color(AppColors.black),
                      ),
                    ),
                    const SizedBox(height: 12),
                    IgnorePointer(
                      ignoring: !_distributionEnabled,
                      child: Opacity(
                        opacity: _distributionEnabled ? 1 : 0.4,
                        child: Row(
                          children: [
                            Expanded(
                              child: ModalTextField(
                                controller: _companyAmountController,
                                label: 'Компания',
                                hintText: '0',
                                keyboardType: TextInputType.number,
                                onChanged: _handleCompanyAmountChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ModalTextField(
                                controller: _investorAmountController,
                                label: 'Инвестор',
                                hintText: '0',
                                keyboardType: TextInputType.number,
                                onChanged: _handleInvestorAmountChanged,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    IgnorePointer(
                      ignoring: !_distributionEnabled,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbColor: const Color(AppColors.primary),
                          activeTrackColor: const Color(AppColors.primary),
                          inactiveTrackColor: const Color(
                            AppColors.primaryLight,
                          ),
                          disabledThumbColor: const Color(0xFFB8BEC8),
                          disabledActiveTrackColor: const Color(
                            AppColors.primaryLight,
                          ),
                          disabledInactiveTrackColor: const Color(0xFFE0E3EB),
                          trackHeight: 6,
                        ),
                        child: Slider(
                          min: 0,
                          max: 100,
                          value: _companyShare,
                          onChanged: _distributionEnabled
                              ? _updateSharesFromSlider
                              : null,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _shareLegend(
                          'Компания: ${_companyShareController.text}%',
                          const Color(AppColors.primary),
                        ),
                        const Spacer(),
                        _shareLegend(
                          'Инвестор: ${_investorShareController.text}%',
                          const Color(0xFF00A092),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                            isPrimary: true,
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

  Widget _shareLegend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppStyle.manrope(
            size: 14,
            weight: FontWeight.w500,
            color: const Color(AppColors.black),
          ),
        ),
      ],
    );
  }

  void _handleAmountChange() {
    var updated = false;
    if (_amountError != null) {
      updated = true;
      setState(() => _amountError = null);
    }
    _formatCurrencyInput(_amountController);
    final distributionChanged = _updateDistributionAvailability();
    if (!updated && !distributionChanged) {
      setState(() {});
    }
  }

  void _handleCommentChange() {
    setState(() {});
  }

  void _formatCurrencyInput(TextEditingController controller) {
    if (_isFormattingAmount) return;
    final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _isFormattingAmount = true;
      controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _isFormattingAmount = false;
      return;
    }
    final value = double.parse(digits);
    final formatted = _formatInputValue(value);
    _isFormattingAmount = true;
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingAmount = false;
  }

  bool _updateDistributionAvailability() {
    final enabled = _getTotalAmount() > 0;
    if (_distributionEnabled != enabled) {
      setState(() {
        _distributionEnabled = enabled;
        if (!enabled) {
          _companyShare = 100;
          _companyShareController.text = '100';
          _investorShareController.text = '0';
          _companyAmountController.text = _formatInputValue(0);
          _investorAmountController.text = _formatInputValue(0);
        } else {
          _updateAmountsFromPercent(_companyShare, 100 - _companyShare);
        }
      });
      return true;
    } else if (enabled) {
      _updateAmountsFromPercent(_companyShare, 100 - _companyShare);
    }
    return false;
  }

  void _updateAmountsFromPercent(
    double companyPercent,
    double investorPercent,
  ) {
    final total = _getTotalAmount();
    if (total <= 0) {
      _companyAmountController.text = _formatInputValue(0);
      _investorAmountController.text = _formatInputValue(0);
      return;
    }
    final companyAmount = (total * companyPercent / 100).round().toDouble();
    final investorAmount = (total * investorPercent / 100).round().toDouble();
    _companyAmountController.text = _formatInputValue(companyAmount);
    _investorAmountController.text = _formatInputValue(investorAmount);
  }

  void _handleCompanyAmountChanged(String value) {
    final amount = _parseAmount(value);
    final total = _getTotalAmount();
    if (total <= 0) return;
    final clamped = amount.clamp(0, total).toDouble();
    _companyAmountController.text = _formatInputValue(clamped);
    final investorAmount = (total - clamped).clamp(0, total).toDouble();
    _investorAmountController.text = _formatInputValue(investorAmount);
    final companyPercent = (clamped / total * 100).round();
    final investorPercent = 100 - companyPercent;
    _companyShareController.text = companyPercent.toString();
    _investorShareController.text = investorPercent.toString();
    setState(() => _companyShare = companyPercent.toDouble());
  }

  void _handleInvestorAmountChanged(String value) {
    final amount = _parseAmount(value);
    final total = _getTotalAmount();
    if (total <= 0) return;
    final clamped = amount.clamp(0, total).toDouble();
    _investorAmountController.text = _formatInputValue(clamped);
    final companyAmount = (total - clamped).clamp(0, total).toDouble();
    _companyAmountController.text = _formatInputValue(companyAmount);
    final investorPercent = (clamped / total * 100).round();
    final companyPercent = 100 - investorPercent;
    _companyShareController.text = companyPercent.toString();
    _investorShareController.text = investorPercent.toString();
    setState(() => _companyShare = companyPercent.toDouble());
  }

  double _parseAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  double _getTotalAmount() {
    final cleaned = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatMoney(double value) => _formatCurrencyValue(value);

  String _formatCurrencyValue(double amount) {
    final formatter = NumberFormat.decimalPattern('ru_RU');
    return formatter.format(amount).replaceAll('.', ' ');
  }

  String _formatInputValue(double amount) {
    final formatter = NumberFormat.decimalPattern('ru_RU');
    final result = formatter.format(amount);
    return result.replaceAll('.', ' ');
  }
}

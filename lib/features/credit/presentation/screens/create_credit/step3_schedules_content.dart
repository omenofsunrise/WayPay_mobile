import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/custom_checkbox.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_input.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_select.dart';

class Step3SchedulesContent extends StatefulWidget {
  final bool nextMonthStart;
  final ValueChanged<bool> onNextMonthStartChanged;
  final double firstPayment;
  final int termMonths;
  final int? paymentDay;
  final ValueChanged<int> onPaymentDayChanged;
  final ValueChanged<double> onFirstPaymentChanged;
  final ValueChanged<int> onTermMonthsChanged;
  final double totalAmount;

  const Step3SchedulesContent({
    super.key,
    required this.nextMonthStart,
    required this.onNextMonthStartChanged,
    required this.firstPayment,
    required this.termMonths,
    required this.paymentDay,
    required this.onPaymentDayChanged,
    required this.onFirstPaymentChanged,
    required this.onTermMonthsChanged,
    required this.totalAmount,
  });

  @override
  State<Step3SchedulesContent> createState() => _Step3SchedulesContentState();
}

class _Step3SchedulesContentState extends State<Step3SchedulesContent> {
  late TextEditingController _firstPaymentPercentController;
  late TextEditingController _firstPaymentAmountController;
  late TextEditingController _termMonthsController;

  @override
  void initState() {
    super.initState();
    _firstPaymentPercentController = TextEditingController();
    _firstPaymentAmountController = TextEditingController();
    _termMonthsController = TextEditingController();

    _updateControllers();
  }

  @override
  void didUpdateWidget(Step3SchedulesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllers();
  }

  void _updateControllers() {
    final currentPercentText = _firstPaymentPercentController.text;
    final newPercent = widget.firstPayment > 0 && widget.totalAmount > 0
        ? (widget.firstPayment / widget.totalAmount * 100).round()
        : 0;
    final newPercentText = newPercent.toString();

    if (currentPercentText != newPercentText) {
      _firstPaymentPercentController.text = newPercentText;
    }

    final currentAmountText = _firstPaymentAmountController.text;
    final newAmountText = widget.firstPayment > 0
        ? widget.firstPayment.toInt().toString()
        : '0';

    if (currentAmountText != newAmountText) {
      _firstPaymentAmountController.text = newAmountText;
    }

    final currentTermText = _termMonthsController.text;
    final newTermText = widget.termMonths > 0
        ? widget.termMonths.toString()
        : '';

    if (currentTermText != newTermText) {
      _termMonthsController.text = newTermText;
    }
  }

  void _handlePercentInput(String percentValue) {
    final filteredValue = percentValue.replaceAll(RegExp(r'[^0-9]'), '');

    if (filteredValue != percentValue) {
      return;
    }

    if (filteredValue.isNotEmpty) {
      final percent = int.tryParse(filteredValue) ?? 0;
      final clampedPercent = percent.clamp(0, 100);

      double newAmount = 0;
      if (widget.totalAmount > 0 && clampedPercent > 0) {
        newAmount = (widget.totalAmount * clampedPercent / 100).floorToDouble();
      }

      widget.onFirstPaymentChanged(newAmount);
    } else {
      widget.onFirstPaymentChanged(0);
    }
  }

  void _handleAmountInput(String amountValue) {
    final filteredValue = amountValue.replaceAll(RegExp(r'[^0-9]'), '');

    if (filteredValue != amountValue) {
      return;
    }

    if (filteredValue.isNotEmpty) {
      final amount = double.tryParse(filteredValue) ?? 0;
      double clampedAmount = amount.clamp(0, widget.totalAmount);

      widget.onFirstPaymentChanged(clampedAmount);
    } else {
      widget.onFirstPaymentChanged(0);
    }
  }

  void _handleTermMonthsInput(String value) {
    final filteredValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (filteredValue != value) {
      return;
    }

    if (value.isNotEmpty) {
      final termMonths = int.tryParse(value);
      if (termMonths != null && termMonths > 0) {
        widget.onTermMonthsChanged(termMonths);
      }
    } else {
      widget.onTermMonthsChanged(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCheckbox(
          value: widget.nextMonthStart,
          onChanged: (value) => widget.onNextMonthStartChanged(value ?? false),
          label: 'Начинать выплаты со след месяца',
        ),

        const SizedBox(height: 24),

        CustomInput(
          controller: _firstPaymentPercentController,
          label: 'Первоначальный взнос %',
          keyboardType: TextInputType.number,
          onUserInput: _handlePercentInput,
        ),

        const SizedBox(height: 16),

        CustomInput(
          controller: _firstPaymentAmountController,
          label: 'Рублей',
          keyboardType: TextInputType.number,
          onChanged: _handleAmountInput,
        ),

        const SizedBox(height: 16),

        CustomInput(
          controller: _termMonthsController,
          label: 'Количество месяцев',
          keyboardType: TextInputType.number,
          onChanged: _handleTermMonthsInput,
        ),

        const SizedBox(height: 16),

        CustomSelect<int>(
          customPlaceholder: 'Уплата до',
          value: widget.paymentDay,
          onChange: widget.onPaymentDayChanged,
          options: List.generate(31, (index) {
            final day = index + 1;
            return CustomSelectOption<int>(value: day, label: '$day число');
          }),
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(AppColors.lightGreyBackground),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(AppColors.primary).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Финансовая информация',
                style: AppStyle.manrope(
                  size: 14,
                  weight: FontWeight.w500,
                  color: Color(AppColors.darkGrey),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Общая сумма:',
                    style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
                  ),
                  Text(
                    '${widget.totalAmount.toStringAsFixed(2)} ₽',
                    style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Первоначальный взнос:',
                    style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
                  ),
                  Text(
                    '${widget.firstPayment.toInt()} ₽',
                    style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Сумма кредита:',
                    style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
                  ),
                  Text(
                    '${(widget.totalAmount - widget.firstPayment).toStringAsFixed(2)} ₽',
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Color(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _firstPaymentPercentController.dispose();
    _firstPaymentAmountController.dispose();
    _termMonthsController.dispose();
    super.dispose();
  }
}

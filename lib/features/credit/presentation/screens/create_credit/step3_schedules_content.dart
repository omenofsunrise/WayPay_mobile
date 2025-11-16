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

  bool _updatingFromPercent = false;
  bool _updatingFromAmount = false;
  bool _externalUpdate = false;

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

    // Обновляем контроллеры только если изменения пришли извне
    if (!_updatingFromPercent && !_updatingFromAmount) {
      _externalUpdate = true;
      _updateControllers();
      _externalUpdate = false;
    }
  }

  void _updateControllers() {
    // Обновляем поле процента (только целые числа)
    if (widget.firstPayment > 0 && widget.totalAmount > 0) {
      final percent = (widget.firstPayment / widget.totalAmount * 100).round();
      if (_firstPaymentPercentController.text != percent.toString()) {
        _firstPaymentPercentController.text = percent.toString();
      }
    } else {
      if (_firstPaymentPercentController.text.isNotEmpty && !_externalUpdate) {
        _firstPaymentPercentController.text = '';
      }
    }

    // Обновляем поле суммы (полная сумма с копейками)
    final newAmountText = widget.firstPayment > 0
        ? widget.firstPayment.toStringAsFixed(2)
        : '';
    if (_firstPaymentAmountController.text != newAmountText) {
      _firstPaymentAmountController.text = newAmountText;
    }

    // Обновляем поле месяцев
    final newTermText = widget.termMonths > 0
        ? widget.termMonths.toString()
        : '';
    if (_termMonthsController.text != newTermText) {
      _termMonthsController.text = newTermText;
    }
  }

  void _updateFromPercent(String percentValue) {
    // Если обновление идет извне - игнорируем
    if (_externalUpdate) return;

    // Фильтруем запятые и точки
    final filteredValue = percentValue.replaceAll(RegExp(r'[.,]'), '');
    if (filteredValue != percentValue) {
      _firstPaymentPercentController.text = filteredValue;
      _firstPaymentPercentController.selection = TextSelection.fromPosition(
        TextPosition(offset: filteredValue.length),
      );
      return;
    }

    if (percentValue.isNotEmpty && widget.totalAmount > 0) {
      final percent = int.tryParse(percentValue);
      if (percent != null && percent >= 0 && percent <= 100) {
        _updatingFromPercent = true;
        final amount = widget.totalAmount * percent / 100;
        widget.onFirstPaymentChanged(amount);

        // Обновляем поле суммы сразу (без ожидания внешнего обновления)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _firstPaymentAmountController.text = amount.toStringAsFixed(2);
          _updatingFromPercent = false;
        });
      }
    } else if (percentValue.isEmpty) {
      _updatingFromPercent = true;
      widget.onFirstPaymentChanged(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _firstPaymentAmountController.text = '';
        _updatingFromPercent = false;
      });
    }
  }

  void _updateFromAmount(String amountValue) {
    // Если обновление идет извне - игнорируем
    if (_externalUpdate) return;

    // Фильтруем запятые и точки, но сохраняем десятичные знаки
    final filteredValue = amountValue.replaceAll(RegExp(r'[^0-9.]'), '');

    // Проверяем на множественные точки
    final dotCount = filteredValue.split('.').length - 1;
    if (dotCount > 1) {
      // Убираем лишние точки
      final parts = filteredValue.split('.');
      final validValue = '${parts[0]}.${parts.sublist(1).join('')}';
      _firstPaymentAmountController.text = validValue;
      _firstPaymentAmountController.selection = TextSelection.fromPosition(
        TextPosition(offset: validValue.length),
      );
      return;
    }

    if (filteredValue != amountValue) {
      _firstPaymentAmountController.text = filteredValue;
      _firstPaymentAmountController.selection = TextSelection.fromPosition(
        TextPosition(offset: filteredValue.length),
      );
      return;
    }

    if (amountValue.isNotEmpty && widget.totalAmount > 0) {
      final amount = double.tryParse(amountValue);
      if (amount != null && amount >= 0 && amount <= widget.totalAmount) {
        _updatingFromAmount = true;
        widget.onFirstPaymentChanged(amount);

        // Обновляем поле процента сразу
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final percent = (amount / widget.totalAmount * 100).round();
          _firstPaymentPercentController.text = percent.toString();
          _updatingFromAmount = false;
        });
      }
    } else if (amountValue.isEmpty) {
      _updatingFromAmount = true;
      widget.onFirstPaymentChanged(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _firstPaymentPercentController.text = '';
        _updatingFromAmount = false;
      });
    }
  }

  void _updateTermMonths(String value) {
    // Фильтруем запятые и точки для месяцев
    final filteredValue = value.replaceAll(RegExp(r'[.,]'), '');
    if (filteredValue != value) {
      _termMonthsController.text = filteredValue;
      _termMonthsController.selection = TextSelection.fromPosition(
        TextPosition(offset: filteredValue.length),
      );
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
        // Чекбокс "Начинать выплаты со след месяца"
        CustomCheckbox(
          value: widget.nextMonthStart,
          onChanged: (value) => widget.onNextMonthStartChanged(value ?? false),
          label: 'Начинать выплаты со след месяца',
        ),

        const SizedBox(height: 24),

        // Поле "Первоначальный взнос %"
        CustomInput(
          controller: _firstPaymentPercentController,
          label: 'Первоначальный взнос %',
          keyboardType: TextInputType.number,
          onChanged: _updateFromPercent,
        ),

        const SizedBox(height: 16),

        // Поле "Рублей"
        CustomInput(
          controller: _firstPaymentAmountController,
          label: 'Рублей',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: _updateFromAmount,
        ),

        const SizedBox(height: 16),

        // Поле "Количество месяцев"
        CustomInput(
          controller: _termMonthsController,
          label: 'Количество месяцев',
          keyboardType: TextInputType.number,
          onChanged: _updateTermMonths,
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

        // Итоговая информация
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
                    '${widget.firstPayment.toStringAsFixed(2)} ₽',
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_creation_state.dart';
import 'package:waypay_mobile/features/credit/data/models/schedule_preview_model.dart';
import 'package:waypay_mobile/features/credit/presentation/cubit/credit_creation_provider.dart';

class Step3SchedulesContent extends StatefulWidget {
  final bool nextMonthStart;
  final bool currentMonthStart;
  final ValueChanged<bool> onNextMonthStartChanged;
  final ValueChanged<bool> onCurrentMonthStartChanged;
  final VoidCallback onNearestMonthStartChanged;
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
    required this.currentMonthStart,
    required this.onNextMonthStartChanged,
    required this.onCurrentMonthStartChanged,
    required this.onNearestMonthStartChanged,
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

enum _PaymentStartOption { current, next, later }

class _Step3SchedulesContentState extends State<Step3SchedulesContent> {
  late TextEditingController _firstPaymentPercentController;
  late TextEditingController _firstPaymentAmountController;
  late TextEditingController _termMonthsController;
  late TextEditingController _paymentDayController;
  Timer? _debounceTimer;
  bool _isFormattingAmount = false;

  @override
  void initState() {
    super.initState();

    _firstPaymentPercentController = TextEditingController();
    _firstPaymentAmountController = TextEditingController();
    _termMonthsController = TextEditingController();
    _paymentDayController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllers();
      _loadSchedulePreview();
    });
  }

  _PaymentStartOption get _startOption {
    if (widget.currentMonthStart) return _PaymentStartOption.current;
    if (widget.nextMonthStart) return _PaymentStartOption.next;
    return _PaymentStartOption.later;
  }

  @override
  void didUpdateWidget(Step3SchedulesContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllers();
    if (oldWidget.firstPayment != widget.firstPayment ||
        oldWidget.termMonths != widget.termMonths ||
        oldWidget.paymentDay != widget.paymentDay ||
        oldWidget.currentMonthStart != widget.currentMonthStart ||
        oldWidget.nextMonthStart != widget.nextMonthStart) {
      _loadSchedulePreviewDebounced();
    }
  }

  void _updateControllers() {
    final currentPercentText = _firstPaymentPercentController.text;
    final newPercent = widget.firstPayment > 0 && widget.totalAmount > 0
        ? (widget.firstPayment / widget.totalAmount * 100).round()
        : 0;
    final newPercentText = newPercent > 0 ? newPercent.toString() : '';

    if (currentPercentText != newPercentText) {
      _firstPaymentPercentController.text = newPercentText;
    }

    final currentAmountDigits = _stripFormatting(
      _firstPaymentAmountController.text,
    );
    final newAmountDigits = widget.firstPayment > 0
        ? widget.firstPayment.floor().toString()
        : '';

    if (currentAmountDigits != newAmountDigits) {
      _firstPaymentAmountController.text = newAmountDigits.isEmpty
          ? ''
          : _formatAmountValue(widget.firstPayment);
    }

    final currentTermText = _termMonthsController.text;
    final newTermText = widget.termMonths > 0
        ? widget.termMonths.toString()
        : '';

    if (currentTermText != newTermText) {
      _termMonthsController.text = newTermText;
    }

    final currentPaymentDay = _paymentDayController.text;
    final newPaymentDayText = widget.paymentDay != null
        ? '${widget.paymentDay} число'
        : '';
    if (currentPaymentDay != newPaymentDayText) {
      _paymentDayController.text = newPaymentDayText;
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
    if (_isFormattingAmount) return;
    final digits = _stripFormatting(amountValue);
    if (digits.isEmpty) {
      _isFormattingAmount = true;
      _firstPaymentAmountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _isFormattingAmount = false;
      widget.onFirstPaymentChanged(0);
      return;
    }

    final amount = double.tryParse(digits) ?? 0;
    final clampedAmount = amount.clamp(0, widget.totalAmount);
    widget.onFirstPaymentChanged(clampedAmount.toDouble());

    final formatted = _formatAmountValue(clampedAmount.toDouble());
    _isFormattingAmount = true;
    _firstPaymentAmountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingAmount = false;
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

  void _handleCurrentMonthSelection() {
    widget.onCurrentMonthStartChanged(true);
    widget.onNextMonthStartChanged(false);
  }

  void _handleNextMonthSelection() {
    widget.onNextMonthStartChanged(true);
    widget.onCurrentMonthStartChanged(false);
  }

  void _handleLaterSelection() {
    widget.onNearestMonthStartChanged();
  }

  void _handleStartOptionChanged(_PaymentStartOption option) {
    switch (option) {
      case _PaymentStartOption.current:
        _handleCurrentMonthSelection();
        break;
      case _PaymentStartOption.next:
        _handleNextMonthSelection();
        break;
      case _PaymentStartOption.later:
        _handleLaterSelection();
        break;
    }
  }

  String _stripFormatting(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  String _formatAmountValue(double value) {
    final formatter = NumberFormat.decimalPattern('ru_RU');
    return formatter.format(value).replaceAll('.', ' ');
  }

  void _loadSchedulePreviewDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadSchedulePreview();
    });
  }

  void _loadSchedulePreview() {
    context.read<CreditCreationCubit>().loadSchedulePreview();
  }

  Future<void> _showPaymentDayPicker() async {
    final selectedDay = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Выберите день платежа',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,
                  child: ListView.separated(
                    itemCount: 31,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      return ListTile(
                        title: Text('$day число'),
                        trailing: widget.paymentDay == day
                            ? const Icon(
                                Icons.check,
                                color: Color(AppColors.primary),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(day),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedDay != null) {
      widget.onPaymentDayChanged(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditCreationCubit, CreditCreationState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'График выплат',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _StartOptionRadio(
              title: 'Начинать выплаты с текущего месяца',
              value: _PaymentStartOption.current,
              groupValue: _startOption,
              onChanged: _handleStartOptionChanged,
            ),
            _StartOptionRadio(
              title: 'Начинать выплаты со следующего месяца',
              value: _PaymentStartOption.next,
              groupValue: _startOption,
              onChanged: _handleStartOptionChanged,
            ),
            _StartOptionRadio(
              title: 'Начинать выплаты через месяц',
              value: _PaymentStartOption.later,
              groupValue: _startOption,
              onChanged: _handleStartOptionChanged,
            ),
            const SizedBox(height: 16),
            ModalTextField(
              controller: _firstPaymentPercentController,
              label: 'Первоначальный взнос, %',
              keyboardType: TextInputType.number,
              onChanged: _handlePercentInput,
            ),

            const SizedBox(height: 16),

            ModalTextField(
              controller: _firstPaymentAmountController,
              label: 'Сумма',
              keyboardType: TextInputType.number,
              onChanged: _handleAmountInput,
            ),

            const SizedBox(height: 16),

            ModalTextField(
              controller: _termMonthsController,
              label: 'Количество месяцев',
              keyboardType: TextInputType.number,
              onChanged: _handleTermMonthsInput,
            ),

            const SizedBox(height: 16),

            ModalTextField(
              controller: _paymentDayController,
              label: 'Уплата до',
              readOnly: true,
              onTap: _showPaymentDayPicker,
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
            ),

            const SizedBox(height: 24),

            // Preview платежей
            _buildSchedulePreview(state),
          ],
        );
      },
    );
  }

  Widget _buildSchedulePreview(CreditCreationState state) {
    if (state.schedulePreviewLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.schedulePreviewError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Text(
          state.schedulePreviewError!,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.schedulePreview.isEmpty) {
      final hasFirstPayment = state.creditRequest.firstPayment > 0;
      final message = hasFirstPayment
          ? 'График станет доступен сразу после расчёта.'
          : 'Введите первоначальный взнос, чтобы рассчитать график платежей.';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(AppColors.darkGrey),
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const _TableHeader(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.schedulePreview.length,
                itemBuilder: (context, index) {
                  final payment = state.schedulePreview[index];
                  return _buildPaymentItem(payment, index);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(SchedulePreviewModel payment, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: index == 0 ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${payment.paymentDate.day.toString().padLeft(2, '0')}.'
                  '${payment.paymentDate.month.toString().padLeft(2, '0')}.'
                  '${payment.paymentDate.year}',
                  style: _tableCellStyle,
                  textAlign: TextAlign.center,
                ),
                if (payment.comment != null && payment.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.comment!,
                    style: TextStyle(
                      color: const Color(AppColors.grey),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_formatAmount(payment.rest)} ₽',
              style: _tableCellStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_formatAmount(payment.paymentAmount)} ₽',
              style: _tableCellStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    final formatter = NumberFormat.decimalPattern('ru_RU');
    return formatter.format(value).replaceAll('\u00A0', ' ');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _firstPaymentPercentController.dispose();
    _firstPaymentAmountController.dispose();
    _termMonthsController.dispose();
    _paymentDayController.dispose();
    super.dispose();
  }
}

class _StartOptionRadio extends StatelessWidget {
  const _StartOptionRadio({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final _PaymentStartOption value;
  final _PaymentStartOption groupValue;
  final ValueChanged<_PaymentStartOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<_PaymentStartOption>(
      value: value,
      groupValue: groupValue,
      onChanged: (option) {
        if (option != null) onChanged(option);
      },
      activeColor: const Color(AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Дата',
              style: _tableHeaderStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Остаток',
              style: _tableHeaderStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Платёж',
              style: _tableHeaderStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

const TextStyle _tableHeaderStyle = TextStyle(
  fontFamily: 'Manrope',
  fontWeight: FontWeight.w500,
  fontSize: 16,
  height: 24 / 16,
);

const TextStyle _tableCellStyle = TextStyle(
  fontFamily: 'Manrope',
  fontWeight: FontWeight.w500,
  fontSize: 16,
  height: 24 / 16,
);

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _Step3SchedulesContentState extends State<Step3SchedulesContent> {
  late TextEditingController _firstPaymentPercentController;
  late TextEditingController _firstPaymentAmountController;
  late TextEditingController _termMonthsController;
  late TextEditingController _paymentDayController;
  Timer? _debounceTimer;

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

  bool get _isNextMonthSelected {
    return widget.nextMonthStart;
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

    final currentPaymentDay = _paymentDayController.text;
    final newPaymentDayText =
        widget.paymentDay != null ? '${widget.paymentDay} число' : '';
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

  void _handleCurrentMonthSelection() {
    widget.onCurrentMonthStartChanged(true);
    widget.onNextMonthStartChanged(false);
  }

  void _handleNextMonthSelection() {
    widget.onNextMonthStartChanged(true);
    widget.onCurrentMonthStartChanged(false);
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
                            ? const Icon(Icons.check,
                                color: Color(AppColors.primary))
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
            _StartNextMonthCheckbox(
              value: _isNextMonthSelected,
              onChanged: (value) {
                if (value) {
                  _handleNextMonthSelection();
                } else {
                  _handleCurrentMonthSelection();
                }
              },
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            state.schedulePreviewError!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment.paymentDate.day.toString().padLeft(2, '0')}.'
                  '${payment.paymentDate.month.toString().padLeft(2, '0')}.'
                  '${payment.paymentDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (payment.comment != null && payment.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.comment!,
                    style: TextStyle(
                      color: Color(AppColors.grey),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${payment.rest.toStringAsFixed(0)} ₽',
              style: const TextStyle(
                color: Color(AppColors.darkGrey),
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${payment.paymentAmount.toStringAsFixed(0)} ₽',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
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

class _StartNextMonthCheckbox extends StatelessWidget {
  const _StartNextMonthCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (val) => onChanged(val ?? false),
            activeColor: const Color(AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Начинать выплаты со следующего месяца',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Дата',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Остаток',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Платёж',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

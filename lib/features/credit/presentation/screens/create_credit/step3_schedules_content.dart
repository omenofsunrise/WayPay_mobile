import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/CustomRadioButton';
import 'package:waypay_mobile/core/widgets/inputs/custom_input.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_select.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_creation_state.dart';
import 'package:waypay_mobile/features/credit/data/models/schedule_preview_model.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
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

  @override
  void initState() {
    super.initState();

    _firstPaymentPercentController = TextEditingController();
    _firstPaymentAmountController = TextEditingController();
    _termMonthsController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllers();
      _loadSchedulePreview();
    });
  }

  bool get _isNearestMonthSelected {
    return !widget.nextMonthStart && !widget.currentMonthStart;
  }

  bool get _isCurrentMonthSelected {
    return widget.currentMonthStart;
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
      _loadSchedulePreview();
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

  void _handleNearestMonthSelection() {
    widget.onNearestMonthStartChanged();
  }

  void _handleCurrentMonthSelection() {
    widget.onCurrentMonthStartChanged(true);
    widget.onNextMonthStartChanged(false);
  }

  void _handleNextMonthSelection() {
    widget.onNextMonthStartChanged(true);
    widget.onCurrentMonthStartChanged(false);
  }

  void _loadSchedulePreview() {
    context.read<CreditBloc>().add(
      LoadSchedulePreviewEvent(
        totalAmount: widget.totalAmount,
        firstPayment: widget.firstPayment,
        termMonths: widget.termMonths,
        paymentDay: widget.paymentDay ?? 1,
        currentMonthStart: widget.currentMonthStart,
        nextMonthStart: widget.nextMonthStart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditCreationCubit, CreditCreationState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Основная информация',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 8),
            CustomRadioButton(
              value: true,
              groupValue: _isNearestMonthSelected,
              onChanged: (_) => _handleNearestMonthSelection(),
              label: 'Начинать с ближайшего месяца',
            ),

            const SizedBox(height: 8),

            CustomRadioButton(
              value: true,
              groupValue: _isCurrentMonthSelected,
              onChanged: (_) => _handleCurrentMonthSelection(),
              label: 'Начинать с текущего месяца',
            ),

            const SizedBox(height: 8),

            CustomRadioButton(
              value: true,
              groupValue: _isNextMonthSelected,
              onChanged: (_) => _handleNextMonthSelection(),
              label: 'Начинать со следующего месяца',
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
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            child: _TableHeader(),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.schedulePreview.length,
            itemBuilder: (context, index) {
              final payment = state.schedulePreview[index];
              return _buildPaymentItem(payment, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentItem(SchedulePreviewModel payment, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(AppColors.greyLight)),
          left: BorderSide(color: Colors.transparent),
          right: BorderSide(color: Colors.transparent),
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
                  style: const TextStyle(fontWeight: FontWeight.w500),
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
              style: TextStyle(color: Color(AppColors.grey), fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              '${payment.paymentAmount.toStringAsFixed(0)} ₽',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.transparent)),
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

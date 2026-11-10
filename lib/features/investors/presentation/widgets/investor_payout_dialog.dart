import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class InvestorPayoutDialog extends StatefulWidget {
  final double maxAmount;
  final double income;
  final double balance;

  const InvestorPayoutDialog({
    super.key,
    required this.maxAmount,
    required this.income,
    required this.balance,
  });

  @override
  State<InvestorPayoutDialog> createState() => _InvestorPayoutDialogState();
}

class _InvestorPayoutDialogState extends State<InvestorPayoutDialog> {
  final _controller = TextEditingController();
  String? errorText;

  void _submit() {
    final value = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      setState(() => errorText = 'Введите корректную сумму');
      return;
    }
    if (value > widget.maxAmount) {
      setState(() => errorText = 'Сумма превышает доступную');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WayPayModal(
      title: 'Выплата инвестору',
      onClose: () => Navigator.pop(context),
      onPrimary: _submit,
      primaryText: 'Выплатить',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTextField(
            controller: _controller,
            label: 'Сумма выплаты',
            hintText: 'Введите сумму',
            errorText: errorText,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          WayPayInfoCard(
            fieldsPerRow: 2,
            fields: [
              WayPayInfoField(
                label: 'Можно вывести',
                value: '${widget.maxAmount.toStringAsFixed(0)} ₽',
              ),
              WayPayInfoField(
                label: 'Доход',
                value: '${widget.income.toStringAsFixed(0)} ₽',
              ),
              WayPayInfoField(
                label: 'Баланс',
                value: '${widget.balance.toStringAsFixed(0)} ₽',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

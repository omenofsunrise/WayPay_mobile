import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class InvestorInvestmentDraft {
  const InvestorInvestmentDraft(this.amount, this.date);

  final double amount;
  final DateTime date;
}

class InvestorInvestmentDialog extends StatefulWidget {
  const InvestorInvestmentDialog({super.key, required this.investorName});

  final String investorName;

  @override
  State<InvestorInvestmentDialog> createState() =>
      _InvestorInvestmentDialogState();
}

class _InvestorInvestmentDialogState extends State<InvestorInvestmentDialog> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _syncDate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _syncDate() {
    _dateController.text = DateFormat('dd.MM.yyyy').format(_date);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('ru', 'RU'),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _date = selected;
      _syncDate();
    });
  }

  void _submit() {
    final value = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (value == null || value <= 0) {
      setState(() => _errorText = 'Введите корректную сумму');
      return;
    }
    Navigator.pop(context, InvestorInvestmentDraft(value, _date));
  }

  @override
  Widget build(BuildContext context) {
    return WayPayModal(
      title: 'Добавить инвестицию',
      subtitle: widget.investorName,
      onClose: () => Navigator.pop(context),
      onPrimary: _submit,
      primaryText: 'Добавить',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTextField(
            controller: _amountController,
            label: 'Сумма инвестиции',
            hintText: 'Введите сумму',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: _errorText,
          ),
          const SizedBox(height: 14),
          ModalTextField(
            controller: _dateController,
            label: 'Дата инвестиции',
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

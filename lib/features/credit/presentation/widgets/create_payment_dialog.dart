import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';

class CreatePaymentDialog extends StatefulWidget {
  final CreditModel credit;

  const CreatePaymentDialog({super.key, required this.credit});

  @override
  State<CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<CreatePaymentDialog> {
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  PaymentType? _selectedType;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый платёж'),
      backgroundColor: Color(AppColors.background),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Сведения о договоре',
            //   style: TextStyle(fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 12),
            // _buildLabeledField('№ договора', widget.credit.id.toString()),
            // _buildLabeledField('Инвестор', widget.credit.investorNickname),
            // _buildLabeledField('Клиент', widget.credit.clientFullName),
            // _buildLabeledField('Телефон', widget.credit.clientPhone),

            // const SizedBox(height: 20),
            // const Text(
            //   'Сведения о платеже',
            //   style: TextStyle(fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 12),
            LabeledTextField(
              label: 'Сумма платежа',
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsSeparatorInputFormatter(),
                LengthLimitingTextInputFormatter(15),
              ],
            ),

            // const SizedBox(height: 12),
            // _buildLabeledField(
            //   'Текущая задолженность',
            //   _formatCurrency(widget.credit.currentMonthDebt),
            // ),
            // _buildLabeledField(
            //   'Остаток всего долга',
            //   _formatCurrency(widget.credit.rest),
            // ),
            const SizedBox(height: 12),
            const Text('Способ оплаты'),
            _buildPaymentTypeSelector(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DefaultButton(
                    text: 'Отмена',
                    onPressed: () => Navigator.pop(context),
                    isGreen: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DefaultButton(
                    text: 'Создать',
                    onPressed: _isSubmitting ? () {} : _submitPayment,
                    isGreen: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        const Text('Дата платежа:'),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Text(
            _selectedDate != null
                ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                : 'Выберите дату',
            style: TextStyle(color: Color(AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Row(
      children: [
        Checkbox(
          value: _selectedType == PaymentType.cash,
          onChanged: (_) {
            setState(() => _selectedType = PaymentType.cash);
          },
        ),
        const Text('Наличные'),
        const SizedBox(width: 16),
        Checkbox(
          value: _selectedType == PaymentType.card,
          onChanged: (_) {
            setState(() => _selectedType = PaymentType.card);
          },
        ),
        const Text('Карта'),
      ],
    );
  }

  Future<void> _submitPayment() async {
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(text);

    if (_selectedDate == null || amount == null || _selectedType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = getIt<PaymentRemoteDataSources>();
      await api.createPayment(
        creditId: widget.credit.id,
        paymentAmount: amount,
        datePayment: _selectedDate!,
        type: _selectedType!,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Платёж успешно создан')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при создании платежа: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatCurrency(num value) {
    final format = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return format.format(value);
  }
}

import 'package:flutter/material.dart';
import 'package:waypay/core/widgets/default_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Выплата инвестору',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите сумму',
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Можно вывести: ${widget.maxAmount.toStringAsFixed(0)} ₽',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Доход: ${widget.income.toStringAsFixed(0)} ₽ | Баланс: ${widget.balance.toStringAsFixed(0)} ₽',
                style: const TextStyle(color: Colors.black45),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DefaultButton(
                      text: 'Отмена',
                      isGreen: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DefaultButton(
                      text: 'Выплатить',
                      isGreen: true,
                      onPressed: () {
                        final value = double.tryParse(_controller.text);
                        if (value == null || value <= 0) {
                          setState(
                            () => errorText = 'Введите корректную сумму',
                          );
                          return;
                        }
                        if (value > widget.maxAmount) {
                          setState(
                            () => errorText = 'Сумма превышает доступную',
                          );
                          return;
                        }
                        Navigator.pop(context, value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

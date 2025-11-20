import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';

class PaymentPreviewCard extends StatelessWidget {
  const PaymentPreviewCard({
    super.key,
    required this.payment,
    this.showStatus = false,
    this.onTap,
  });

  final PaymentItemModel payment;
  final bool showStatus;
  final VoidCallback? onTap;

  String get _formattedDate {
    try {
      final date = DateTime.parse(payment.paymentDate);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return payment.paymentDate;
    }
  }

  String get _formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(payment.paymentAmount);
  }

  String get _formattedClientName {
    final parts = payment.clientFullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) {
      return '${parts.first}\n${parts.last}';
    }
    final firstLine = '${parts[0]} ${parts[1]}';
    final secondLine = parts.sublist(2).join(' ');
    return '$firstLine\n$secondLine';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x05000809),
            offset: Offset(0, 0),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _formattedClientName,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 24 / 16,
                          color: Color(AppColors.black),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '№ ${payment.creditId}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 24 / 14,
                            color: Color(AppColors.darkGrey),
                          ),
                        ),
                        if (showStatus) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 96,
                            height: 24,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(AppColors.primaryLight),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  'Подтверждён',
                                  style: TextStyle(
                                    color: const Color(AppColors.black),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoColumn(
                        label: 'Дата платежа',
                        value: _formattedDate,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _InfoColumn(
                          label: 'Платеж',
                          value: _formattedAmount,
                          valueColor: const Color(AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.label,
    required this.value,
    this.valueColor = const Color(AppColors.black),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 24 / 14,
            color: Color(AppColors.darkGrey),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            height: 24 / 22,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

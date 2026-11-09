import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class QueueClientCard extends StatelessWidget {
  const QueueClientCard({
    super.key,
    required this.number,
    required this.date,
    required this.fullName,
    required this.amount,
    required this.phone,
    this.onTap,
  });

  final String number;
  final String date;
  final String fullName;
  final String amount;
  final String phone;
  final VoidCallback? onTap;

  static const _shadow = [
    BoxShadow(color: Color(0x14000809), offset: Offset(2, 2), blurRadius: 4),
    BoxShadow(color: Color(0x05000809), offset: Offset(0, 0), blurRadius: 6),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      number,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.black),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: WayPayInfoItem(label: 'Сумма', value: amount),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: WayPayInfoItem(
                        label: 'Телефон',
                        value: phone,
                        alignRight: true,
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

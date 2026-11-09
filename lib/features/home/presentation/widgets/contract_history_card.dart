import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ContractHistoryCard extends StatelessWidget {
  const ContractHistoryCard({
    super.key,
    required this.contractNumber,
    required this.contractDate,
    required this.clientName,
    required this.paidAmount,
    required this.remainingAmount,
    this.onTap,
  });

  final String contractNumber;
  final String contractDate;
  final String clientName;
  final String paidAmount;
  final String remainingAmount;
  final VoidCallback? onTap;

  static const _shadow = [
    BoxShadow(
      color: Color(0x14000809),
      offset: Offset(2, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05000809),
      offset: Offset(0, 0),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Договор $contractNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(AppColors.black),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      contractDate,
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
                  clientName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: WayPayInfoItem(
                        label: 'Уплачено',
                        value: paidAmount,
                        valueColor: const Color(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: WayPayInfoItem(
                        label: 'Остаток',
                        value: remainingAmount,
                        valueColor: const Color(AppColors.red),
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

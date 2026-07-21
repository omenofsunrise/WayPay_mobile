import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class ClientApplicationCard extends StatelessWidget {
  const ClientApplicationCard({
    super.key,
    required this.fullName,
    required this.applicationNumber,
    required this.term,
    required this.productName,
    required this.amount,
    this.onTap,
  });

  final String fullName;
  final String applicationNumber;
  final String term;
  final String productName;
  final String amount;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      applicationNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(AppColors.uiBorder),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Срок',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  term,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(AppColors.black),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _InfoRow(
                        label: 'Товар',
                        value: productName,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoRow(
                        label: 'Стоимость',
                        value: amount,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.alignRight = false,
    this.maxLines,
  });

  final String label;
  final String value;
  final bool alignRight;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(AppColors.uiBorder),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: alignRight ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
        ),
      ],
    );
  }
}

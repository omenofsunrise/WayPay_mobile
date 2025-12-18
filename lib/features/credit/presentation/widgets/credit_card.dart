import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/utils/price_formatter.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_modal.dart';
import 'package:waypay_styles/waypay_styles.dart';

class CreditCardWidget extends StatelessWidget {
  final CreditModel credit;
  final VoidCallback? onFavouriteToggle;
  final bool isControl;

  const CreditCardWidget({
    super.key,
    required this.credit,
    this.onFavouriteToggle,
    this.isControl = false,
  });

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CreditFullScreen(credit: credit, isControl: isControl),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 168),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000809),
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
            BoxShadow(
              color: Color(0x05000809),
              blurRadius: 6,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Договор №${credit.id}',
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.uiBorder),
                  ),
                ),
                const Spacer(),
                Text(
                  'от ${_formatDate(credit.creditDate)}',
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.uiBorder),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    credit.clientFullName,
                    style: AppStyle.manrope(
                      size: 16,
                      weight: FontWeight.w500,
                      color: const Color(AppColors.black),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onFavouriteToggle,
                  child: Icon(
                    credit.isFavourite ? Icons.star : Icons.star_border,
                    color: credit.isFavourite ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildValueBlock(
                    label: 'Уплачено',
                    value: PriceFormatter.formatPrice(credit.payed),
                    valueColor: const Color(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildValueBlock(
                    label: 'Остаток',
                    value: PriceFormatter.formatPrice(credit.rest),
                    valueColor: const Color(AppColors.red),
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueBlock({
    required String label,
    required String value,
    required Color valueColor,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyle.manrope(
            size: 16,
            weight: FontWeight.w500,
            color: const Color(AppColors.black),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppStyle.manrope(
            size: 22,
            weight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

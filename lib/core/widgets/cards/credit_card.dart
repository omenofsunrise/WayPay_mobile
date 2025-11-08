import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/utilits/price_formatter.dart';
import 'package:waypay/features/credit/data/models/credit_model.dart';
import 'package:waypay/features/credit/presentation/widgets/credit_modal.dart';

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
        showDialog(
          context: context,
          builder: (_) =>
              CreditFullScreen(credit: credit, isControl: isControl),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Договор №${credit.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 4),
                Text(
                  "от ${_formatDate(credit.creditDate)}",
                  style: const TextStyle(color: Color(AppColors.uiBorder)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    credit.clientFullName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(AppColors.black),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Уплачено',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(AppColors.grey),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        PriceFormatter.formatPrice(credit.payed),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Остаток',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(AppColors.grey),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        PriceFormatter.formatPrice(credit.rest),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

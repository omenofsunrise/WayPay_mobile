import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class DashboardInfoTile extends StatelessWidget {
  final Color circleColor;
  final String iconAsset;
  final String title;
  final String value;
  final String changeText;
  final bool? isGrowth;

  const DashboardInfoTile({
    super.key,
    required this.circleColor,
    required this.iconAsset,
    required this.title,
    required this.value,
    required this.changeText,
    this.isGrowth,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '',
      decimalDigits: 0,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(iconAsset, width: 24, height: 24),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              title,
              style: AppStyle.manrope(size: 15, weight: FontWeight.w500),
            ),
            Text(
              currencyFormatter.format(int.tryParse(value) ?? 0),
              style: AppStyle.manrope(size: 29, weight: FontWeight.w600),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGrowth != null)
                  Icon(
                    isGrowth! ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 36,
                    color: isGrowth!
                        ? Color(AppColors.primary)
                        : Color(AppColors.red),
                  ),
                if (isGrowth != null)
                  SizedBox(
                    width: 140,
                    child: Text(
                      changeText,
                      style: AppStyle.manrope(
                        size: 12,
                        weight: FontWeight.w400,
                        color: isGrowth != null
                            ? (isGrowth!
                                  ? Color(AppColors.primary)
                                  : Color(AppColors.red))
                            : Colors.black,
                      ),
                    ),
                  ),
                if (isGrowth == null)
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Отсутвует активность',
                      style: AppStyle.manrope(
                        size: 12,
                        weight: FontWeight.w400,
                        color: Color(AppColors.greyLight),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

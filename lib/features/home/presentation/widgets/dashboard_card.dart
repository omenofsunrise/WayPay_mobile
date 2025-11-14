import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final String? description;
  final String? additionalValue;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.valueColor = const Color(AppColors.primary),
    this.description,
    this.additionalValue,
    this.backgroundColor = const Color(AppColors.white),
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 6.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A001924),
                offset: Offset(0, 4),
                blurRadius: 6,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Color(0x1A001924),
                offset: Offset(0, 2),
                blurRadius: 4,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.darkGrey),
                  ),
                ),

                const SizedBox(height: 8),

                if (description != null) ...[
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                      ),
                    ),
                    const Spacer(),
                    if (additionalValue != null)
                      Text(
                        additionalValue!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(AppColors.black),
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

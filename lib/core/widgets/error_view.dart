import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Не удалось загрузить данные',
    this.retryLabel = 'Повторить',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEFEA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(AppColors.red),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppStyle.manrope(
                size: 18,
                weight: FontWeight.w600,
                color: const Color(AppColors.black),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w400,
                color: const Color(0xFF7C838D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DefaultButton(
                text: retryLabel,
                isGreen: true,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/routes/routes.dart';

class ConfirmationScreen extends StatefulWidget {
  final String phone;

  const ConfirmationScreen({super.key, required this.phone});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(
              'Подтверждение авторизации',
              style: AppStyle.inter(
                size: 24,
                weight: FontWeight.w600,
                color: const Color(AppColors.black),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.phone, style: AppStyle.manrope16),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Авторизация успешно подтверждена!',
                    style: AppStyle.inter(
                      size: 18,
                      weight: FontWeight.w600,
                      color: const Color(AppColors.black),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DefaultButton(
                    text: 'Продолжить',
                    isGreen: true,
                    onPressed: () {
                      context.pushReplacementNamed(Routes.pinCodeScreen.toName);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

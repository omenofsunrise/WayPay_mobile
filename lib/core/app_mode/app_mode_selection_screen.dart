import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/app_mode/app_mode.dart';

class AppModeSelectionScreen extends StatelessWidget {
  const AppModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: const Color(AppColors.background),
      theme: WayPayTheme.light,
      home: Scaffold(
        backgroundColor: const Color(AppColors.background),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  'Выберите сервис',
                  style: AppStyle.manrope(
                    size: 24,
                    weight: FontWeight.w600,
                    color: const Color(AppColors.black),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'WayPay и ЧС+ — отдельные сервисы со своей авторизацией.',
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.uiBorder),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: DefaultButton(
                    text: 'WayPay CRM',
                    isPrimary: true,
                    onPressed: () =>
                        AppModeController.instance.switchTo(AppMode.waypay),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DefaultButton(
                    text: 'ЧС+',
                    onPressed: () => AppModeController.instance.switchTo(
                      AppMode.blacklistPlus,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

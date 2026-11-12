import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/app_mode/app_mode.dart';

class AppModeSelectionScreen extends StatelessWidget {
  const AppModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: WayPayTheme.light,
      home: Scaffold(
        backgroundColor: const Color(AppColors.background),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'Выберите программу',
                  style: AppStyle.manrope(
                    size: 28,
                    weight: FontWeight.w700,
                    color: const Color(AppColors.black),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'WayPay и ЧС+ используют разные аккаунты и отдельную авторизацию.',
                  style: AppStyle.manrope(
                    size: 15,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.uiBorder),
                  ),
                ),
                const SizedBox(height: 28),
                _ModeCard(
                  title: 'WayPay CRM',
                  description:
                      'Договоры, платежи, клиенты и управление компанией',
                  icon: Icons.business_center_outlined,
                  onTap: () =>
                      AppModeController.instance.switchTo(AppMode.waypay),
                ),
                const SizedBox(height: 14),
                _ModeCard(
                  title: 'ЧС+',
                  description: 'Проверка людей и работа с базой ЧС+',
                  icon: Icons.policy_outlined,
                  onTap: () => AppModeController.instance.switchTo(
                    AppMode.blacklistPlus,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WayPaySurfaceCard(
      onTap: onTap,
      showBorder: true,
      child: Row(
        children: [
          WayPayIconBadge(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyle.manrope(
                    size: 18,
                    weight: FontWeight.w700,
                    color: const Color(AppColors.black),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: AppStyle.manrope(
                    size: 13,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.uiBorder),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(AppColors.primary),
          ),
        ],
      ),
    );
  }
}

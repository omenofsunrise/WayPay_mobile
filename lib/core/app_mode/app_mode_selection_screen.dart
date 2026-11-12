import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/app_mode/app_mode.dart';

class AppModeSelectionScreen extends StatefulWidget {
  const AppModeSelectionScreen({super.key});

  @override
  State<AppModeSelectionScreen> createState() => _AppModeSelectionScreenState();
}

class _AppModeSelectionScreenState extends State<AppModeSelectionScreen> {
  AppMode? _openingMode;

  Future<void> _open(AppMode mode) async {
    if (_openingMode != null) return;
    setState(() => _openingMode = mode);
    try {
      await AppModeController.instance.switchTo(mode);
    } finally {
      if (mounted) setState(() => _openingMode = null);
    }
  }

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
                    text: _openingMode == AppMode.waypay
                        ? 'Открываем...'
                        : 'WayPay CRM',
                    isPrimary: true,
                    showIcon: _openingMode == AppMode.waypay,
                    iconWidget: _openingMode == AppMode.waypay
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : null,
                    onPressed: _openingMode == null
                        ? () => _open(AppMode.waypay)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DefaultButton(
                    text: _openingMode == AppMode.blacklistPlus
                        ? 'Открываем...'
                        : 'ЧС+',
                    showIcon: _openingMode == AppMode.blacklistPlus,
                    iconWidget: _openingMode == AppMode.blacklistPlus
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onPressed: _openingMode == null
                        ? () => _open(AppMode.blacklistPlus)
                        : null,
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

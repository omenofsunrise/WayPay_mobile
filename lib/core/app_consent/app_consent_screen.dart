import 'package:flutter/material.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/app_consent/app_consent.dart';

class AppConsentScreen extends StatefulWidget {
  const AppConsentScreen({super.key});

  @override
  State<AppConsentScreen> createState() => _AppConsentScreenState();
}

class _AppConsentScreenState extends State<AppConsentScreen> {
  bool _showPolicy = false;
  bool _isAccepting = false;

  Future<void> _accept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);
    await AppConsentController.instance.accept();
    if (mounted) setState(() => _isAccepting = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: const Color(AppColors.background),
      theme: WayPayTheme.light,
      home: _showPolicy ? _policyScreen() : _introScreen(),
    );
  }

  Widget _introScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/app_icon.png',
                width: 124,
                height: 124,
              ),
              const SizedBox(height: 40),
              Text(
                'Добро пожаловать!',
                textAlign: TextAlign.center,
                style: AppStyle.manrope(size: 24, weight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Для продолжения ознакомьтесь и примите политику конфиденциальности.',
                textAlign: TextAlign.center,
                style: AppStyle.manrope(
                  size: 16,
                  weight: FontWeight.w400,
                  color: const Color(AppColors.uiBorder),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: DefaultButton(
                  text: 'Ознакомиться',
                  isPrimary: true,
                  onPressed: () => setState(() => _showPolicy = true),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyScreen() {
    const sections = <(String, String)>[
      (
        '1. Общие положения',
        'Настоящая Политика конфиденциальности персональных данных действует в отношении всей информации, которую приложение может получить о пользователе во время использования.',
      ),
      (
        '2. Персональные данные пользователей',
        'Приложение может собирать и обрабатывать следующие персональные данные: имя, контактные данные (телефон, email), технические данные устройства (модель, версия ОС).',
      ),
      (
        '3. Цели сбора персональных данных',
        'Персональные данные собираются для предоставления услуг, улучшения качества работы приложения и связи с пользователем.',
      ),
      (
        '4. Условия обработки персональных данных',
        'Обработка персональных данных осуществляется с согласия пользователя. Приложение принимает необходимые меры для защиты персональных данных.',
      ),
      (
        '5. Контактная информация',
        'По вопросам, связанным с политикой конфиденциальности, вы можете обратиться по телефону: 8 (995) 702-23-04 (Элипханов Ибрахим Султанович).',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Header(
                title: 'Конфиденциальность',
                showBackButton: true,
                showNotifications: false,
                showAvatar: false,
                onBackPressed: () => setState(() => _showPolicy = false),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  for (final section in sections) ...[
                    Text(
                      section.$1,
                      style: AppStyle.manrope(
                        size: 18,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.$2,
                      textAlign: TextAlign.justify,
                      style: AppStyle.manrope(
                        size: 15,
                        weight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: _isAccepting
                        ? const Center(child: CircularProgressIndicator())
                        : DefaultButton(
                            text: 'Принять и продолжить',
                            isPrimary: true,
                            onPressed: _accept,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

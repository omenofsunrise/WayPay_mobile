import 'package:flutter/material.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(AppColors.darkGrey)),
          tooltip: 'Назад',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Политика конфиденциальности',
          style: AppStyle.medium20.copyWith(color: const Color(AppColors.background)),
        ),
      ),
      backgroundColor: Color(AppColors.background),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '1. Общие положения',
              style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                textAlign: TextAlign.justify,
                'Настоящая Политика конфиденциальности персональных данных (далее - Политика конфиденциальности) действует в отношении всей информации, которую приложение может получить о пользователе во время использования.',
                style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '2. Персональные данные пользователей',
              textAlign: TextAlign.center,
              style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                textAlign: TextAlign.justify,
                'Приложение может собирать и обрабатывать следующие персональные данные: имя, контактные данные (телефон, email), технические данные устройства (модель, версия ОС).',
                style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '3. Цели сбора персональных данных',
              style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                textAlign: TextAlign.justify,
                'Персональные данные собираются для: предоставления услуг, улучшения качества работы приложения, связи с пользователем.',
                style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '4. Условия обработки персональных данных',
              textAlign: TextAlign.center,
              style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                textAlign: TextAlign.justify,
                'Обработка персональных данных осуществляется с согласия пользователя. Приложение принимает необходимые меры для защиты персональных данных.',
                style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '5. Контактная информация',
              style: AppStyle.manrope(size: 18, weight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                textAlign: TextAlign.justify,
                'По вопросам, связанным с политикой конфиденциальности, вы можете обратиться по телефону: 8 (995) 702-23-04 (Элипханов Ибрахим Султанович).',
                style: AppStyle.manrope(size: 16, weight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

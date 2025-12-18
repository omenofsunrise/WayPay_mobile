import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/main_client_card.dart';
import 'package:waypay_mobile/routes/routes.dart';

class FinanceMainScreen extends StatelessWidget {
  const FinanceMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Финансы',
                showBackButton: true,
                showNotifications: true,
              ),
              const SizedBox(height: 16),
              MainClientCard(
                icon: Icons.account_balance_outlined,
                title: 'Бюджет',
                value: '',
                onTap: () =>
                    context.pushNamed(Routes.budgetApplicationsScreen.toName),
              ),
              MainClientCard(
                icon: Icons.currency_ruble_outlined,
                title: 'Доходы от платежей',
                value: '',
                onTap: () =>
                    context.pushNamed(Routes.paymentIncomeScreen.toName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

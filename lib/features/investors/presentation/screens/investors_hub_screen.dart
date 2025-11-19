import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/routes/routes.dart';

class InvestorsHubScreen extends StatelessWidget {
  const InvestorsHubScreen({super.key});

  void _openInvestorsList(BuildContext context) {
    context.pushNamed(Routes.investorsScreen.toName);
  }

  void _openInvestorsPool(BuildContext context) {
    context.pushNamed(Routes.investorPoolScreen.toName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Инвесторы',
                showBackButton: true,
                showNotifications: true,
              ),
              const SizedBox(height: 24),
              _InvestorsCard(
                icon: Icons.person_outline,
                label: 'Инвесторы',
                onTap: () => _openInvestorsList(context),
              ),
              const SizedBox(height: 16),
              _InvestorsCard(
                icon: Icons.account_balance_outlined,
                label: 'Пул инвесторов',
                onTap: () => _openInvestorsPool(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestorsCard extends StatelessWidget {
  const _InvestorsCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(AppColors.black)),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(AppColors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

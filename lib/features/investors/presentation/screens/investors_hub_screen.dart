import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/deleted_investors_screen.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

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
                showNotifications: false,
              ),
              const SizedBox(height: 24),
              WayPayEntityCard(
                title: 'Инвесторы',
                leading: const WayPayIconBadge(icon: Icons.person_outline),
                onTap: () => _openInvestorsList(context),
              ),
              const SizedBox(height: 16),
              WayPayEntityCard(
                title: 'Архив инвесторов',
                leading: const WayPayIconBadge(icon: Icons.archive_outlined),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeletedInvestorsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              WayPayEntityCard(
                title: 'Пулы инвесторов',
                leading: const WayPayIconBadge(
                  icon: Icons.account_balance_outlined,
                ),
                onTap: () => _openInvestorsPool(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

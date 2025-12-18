import 'package:flutter/material.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/profile/presentation/widgets/credit_count.dart';
import 'package:waypay_mobile/features/profile/presentation/widgets/payment_stats_table.dart';
import 'package:waypay_styles/waypay_styles.dart';

class ProfileStatisticsScreen extends StatelessWidget {
  final int? employeeId;
  const ProfileStatisticsScreen({super.key, this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Статистика',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              PaymentStatsProfileTable(employeeId: employeeId),
              const SizedBox(height: 24),
              CreditCount(employeeId: employeeId),
            ],
          ),
        ),
      ),
    );
  }
}

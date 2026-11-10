import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_report_screen.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class InvestorCard extends StatefulWidget {
  final InvestorsModel investor;

  const InvestorCard({super.key, required this.investor});

  @override
  State<InvestorCard> createState() => _InvestorCardState();
}

class _InvestorCardState extends State<InvestorCard> {
  @override
  Widget build(BuildContext context) {
    final isPositive = widget.investor.balance >= 0;
    final userStorage = UserStorage();

    return ValueListenableBuilder<EmployeeRole?>(
      valueListenable: userStorage.roleNotifier,
      builder: (context, role, _) {
        userStorage.canViewContent();

        return WayPayEntityCard(
          title: widget.investor.nickname,
          details: [
            WayPayInfoItem(
              label: 'Касса',
              value: '${widget.investor.balance.toStringAsFixed(0)} ₽',
              valueColor: isPositive
                  ? const Color(AppColors.primaryLight)
                  : const Color(AppColors.pinkTint),
            ),
          ],
          detailColumns: 1,
          backgroundColor: widget.investor.isBlocked
              ? const Color(0xFFFFF2F2)
              : Colors.white,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    InvestorReportScreen(initialInvestor: widget.investor),
              ),
            );
          },
        );
      },
    );
  }
}

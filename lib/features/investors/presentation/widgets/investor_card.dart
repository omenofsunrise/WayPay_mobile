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

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    InvestorReportScreen(initialInvestor: widget.investor),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: widget.investor.isBlocked
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.investor.nickname,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.investor.balance.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPositive
                          ? const Color(AppColors.primaryLight)
                          : const Color(AppColors.pinkTint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/features/analytics/presentation/widgets/contract_count_pie.dart';
import 'package:waypay/features/analytics/presentation/widgets/dashboard_info_card.dart';
import 'package:waypay/features/analytics/presentation/widgets/dropdown.dart';
import 'package:waypay/features/analytics/presentation/widgets/investition_table.dart';
import 'package:waypay/features/analytics/presentation/widgets/payment_dynamic_table.dart';
import 'package:waypay/features/analytics/presentation/widgets/payment_stats_table.dart';
import 'package:waypay/features/analytics/presentation/widgets/sales_purchase_pie_chart.dart';

import 'package:waypay/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  void _reloadData({String? predefinedPeriod, DateTimeRange? range}) {
    final itemsCubit = context.read<AnalyticItemsCubit>();
    final investCubit = context.read<InvestmentDynamicCubit>();
    final sellCubit = context.read<SellInfoCubit>();
    final debtCubit = context.read<DebtDynamicCubit>();

    if (range != null) {
      final start = range.start.toIso8601String();
      final end = range.end.toIso8601String();

      itemsCubit.loadAnalyticItems(start: start, end: end);
      investCubit.loadInvestmentDynamic(start: start, end: end);
      sellCubit.loadSellInfo(start: start, end: end);
      debtCubit.loadDebtDynamic(start: start, end: end);
    } else {
      itemsCubit.loadAnalyticItems(predefinedPeriod: predefinedPeriod);
      investCubit.loadInvestmentDynamic(predefinedPeriod: predefinedPeriod);
      sellCubit.loadSellInfo(predefinedPeriod: predefinedPeriod);
      debtCubit.loadDebtDynamic(predefinedPeriod: predefinedPeriod);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadData(predefinedPeriod: PeriodOption.thisMonth.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Color(AppColors.background),

      appBar: AppBar(
        title: Text('Аналитика', style: AppStyle.manrope(size: 25, weight: FontWeight.w600)),
        backgroundColor: Color(AppColors.background),
        elevation: 0,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Color(AppColors.grey)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PeriodDropdown(
              onChanged: (option, range) {
                final predefined = option?.name;
                _reloadData(predefinedPeriod: predefined, range: range);
              },
            ),
            const SizedBox(height: 16),
            const DashboardInfoCard(),
            const SizedBox(height: 16),
            const PaymentStatsTable(),
            const SizedBox(height: 16),
            const InvestitionTable(),
            const SizedBox(height: 16),
            const PaymentDynamicTable(),
            const SizedBox(height: 16),
            const ContractsPieChart(),
            const SizedBox(height: 16),
            const SalesPurchasesPieChart(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_styles/waypay_styles.dart';

import 'package:waypay_mobile/features/analytics/presentation/widgets/contract_count_pie.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/dashboard_info_card.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/investition_table.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/payment_dynamic_table.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/payment_stats_table.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/sales_purchase_pie_chart.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/period_appbar_action.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/dropdown.dart'
    show PeriodOption;

import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  PeriodOption _selected = PeriodOption.thisMonth;
  DateTimeRange? _customRange;

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
      _reloadData(predefinedPeriod: _selected.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Header(
                title: 'Аналитика',
                showBackButton: true,
                showNotifications: false,
                trailing: PeriodAppBarAction(
                  selected: _selected,
                  onChanged: (option, range) {
                    setState(() {
                      if (range != null) {
                        _customRange = range;
                      } else if (option != null) {
                        _selected = option;
                        _customRange = null;
                      }
                    });
                    _reloadData(predefinedPeriod: option?.name, range: range);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardInfoCard(),
                      SizedBox(height: 16),
                      PaymentStatsTable(),
                      SizedBox(height: 16),
                      InvestitionTable(),
                      SizedBox(height: 16),
                      PaymentDynamicTable(),
                      SizedBox(height: 16),
                      ContractsPieChart(),
                      SizedBox(height: 16),
                      SalesPurchasesPieChart(),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

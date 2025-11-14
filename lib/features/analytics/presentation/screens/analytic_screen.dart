import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/app_drawer/app_drawer.dart';

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
      drawer: const AppDrawer(),

      // зелёная шапка
      backgroundColor: const Color(AppColors.primary),

      appBar: AppBar(
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false, // заголовок прижат к левому краю
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Аналитика',
          style: AppStyle.medium20.copyWith(
            color: const Color(AppColors.background),
          ),
        ),
        actions: [
          PeriodAppBarAction(
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
        ],
      ),

      // закруглённый верх у контента
      body: Container(
        decoration: const BoxDecoration(
          color: Color(AppColors.background),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_state.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class DashboardInfoCard extends StatelessWidget {
  const DashboardInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticItemsCubit, AnalyticItemsState>(
      builder: (context, state) {
        if (state is AnalyticItemsLoading) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AnalyticItemsError) {
          return SizedBox(
            height: 260,
            child: Center(child: Text('Ошибка: ${state.message}')),
          );
        }

        if (state is AnalyticItemsLoaded) {
          final data = state.data;
          final NumberFormat currencyFormatter = NumberFormat.currency(
            locale: 'ru_RU',
            symbol: '₽',
            decimalDigits: 0,
          );
          final NumberFormat numberFormatter = NumberFormat.decimalPattern(
            'ru_RU',
          );

          return GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            children: [
              WayPayMetricCard.asset(
                circleColor: const Color(AppColors.greenTie),
                iconAsset: SvgIcons.investition,
                title: 'Сумма инвестиций',
                value: currencyFormatter.format(data.investmentAmount),
              ),
              WayPayMetricCard.asset(
                circleColor: const Color(AppColors.greenTie),
                iconAsset: SvgIcons.cash,
                title: 'Остаток в кассе',
                value: currencyFormatter.format(data.cash),
              ),
              WayPayMetricCard.asset(
                circleColor: const Color(AppColors.greenTie),
                iconAsset: SvgIcons.rub,
                title: 'Сумма остатков',
                value: currencyFormatter.format(data.restAmount),
              ),
              WayPayMetricCard.asset(
                circleColor: const Color(AppColors.orangeTie),
                iconAsset: SvgIcons.delay,
                title: 'Просрочка',
                value: currencyFormatter.format(data.latePayment),
                valueColor: const Color(0xFFFF5A5A),
              ),
              WayPayMetricCard.asset(
                circleColor: const Color(0x4D14BFDB),
                iconAsset: SvgIcons.doc,
                title: 'Активные договоры',
                value: numberFormatter.format(data.activeCredits),
              ),
              WayPayMetricCard.asset(
                circleColor: const Color(0x4D14BFDB),
                iconAsset: SvgIcons.doc,
                title: 'Закрытые договоры',
                value: numberFormatter.format(data.totalCredits),
              ),
            ],
          );
        }

        return const SizedBox(
          height: 260,
          child: Center(child: Text('Нет данных')),
        );
      },
    );
  }
}

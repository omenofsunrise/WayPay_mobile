import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_state.dart';
import 'package:waypay_mobile/features/analytics/presentation/widgets/dashboard_info_tile.dart';

class DashboardInfoCard extends StatelessWidget {
  const DashboardInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticItemsCubit, AnalyticItemsState>(
      builder: (context, state) {
        if (state is AnalyticItemsLoading) {
          return const SizedBox(
            height: 570,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AnalyticItemsError) {
          return SizedBox(
            height: 570,
            child: Center(child: Text('Ошибка: ${state.message}')),
          );
        }

        if (state is AnalyticItemsLoaded) {
          final data = state.data;

          return SizedBox(
            height: 570,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(AppColors.borderColor)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 30,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardInfoTile(
                      circleColor: const Color(AppColors.pinkTie),
                      iconAsset: SvgIcons.chartIcon,
                      title: 'Сумма инвестиций',
                      value: '${data.investmentAmount}',
                      changeText:
                          'на ${data.investmentAmountDiffrence}% по сравнению с прошлым',
                      isGrowth: data.investmentAmountDiffrence != 0
                          ? data.investmentAmountDiffrence >= 0
                          : null,
                    ),
                    DashboardInfoTile(
                      circleColor: const Color(AppColors.greenTie),
                      iconAsset: SvgIcons.moneyIcon,
                      title: 'Остаток в кассе',
                      value: '${data.cash}',
                      changeText:
                          'на ${data.cashDiffrence}% по сравнению с прошлым',
                      isGrowth: data.cashDiffrence != 0
                          ? data.cashDiffrence >= 0
                          : null,
                    ),
                    DashboardInfoTile(
                      circleColor: const Color(AppColors.orangeTie),
                      iconAsset: SvgIcons.clockIcon,
                      title: 'Сумма в просрочке',
                      value: '${data.latePayment}',
                      changeText:
                          'на ${data.latePaymentDiffrence}% по сравнению с прошлым',
                      isGrowth: data.latePaymentDiffrence != 0
                          ? data.latePaymentDiffrence >= 0
                          : null,
                    ),
                    DashboardInfoTile(
                      circleColor: const Color(AppColors.deepGreenTie),
                      iconAsset: SvgIcons.docIcon,
                      title: 'Действующие договора',
                      value: '${data.activeCredits}',
                      changeText:
                          'на ${data.activeCreditsDiffrence}% по сравнению с прошлым',
                      isGrowth: data.activeCreditsDiffrence != 0
                          ? data.activeCreditsDiffrence >= 0
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const SizedBox(
          height: 570,
          child: Center(child: Text('Нет данных')),
        );
      },
    );
  }
}

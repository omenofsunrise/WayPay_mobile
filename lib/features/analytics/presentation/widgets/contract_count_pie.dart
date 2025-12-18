import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_state.dart';
import 'package:waypay_styles/waypay_styles.dart';

class ContractsPieChart extends StatelessWidget {
  const ContractsPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticItemsCubit, AnalyticItemsState>(
      builder: (context, state) {
        if (state is AnalyticItemsLoading) {
          return const SizedBox(
            height: 256,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AnalyticItemsError) {
          return SizedBox(
            height: 256,
            child: Center(child: Text('Ошибка: ${state.message}')),
          );
        }

        if (state is AnalyticItemsLoaded) {
          final data = state.data;

          final activeContracts = data.activeCredits;
          final totalContracts = data.totalCredits;
          final inactiveContracts = (totalContracts - activeContracts).clamp(
            0,
            totalContracts,
          );

          if (totalContracts == 0) {
            return Container(
              width: double.infinity,
              height: 256,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(AppColors.borderColor)),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 60,
                          sections: [
                            PieChartSectionData(
                              color: Color(AppColors.greyLight),
                              value: 1,
                              radius: 25,
                              title: '',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'Данных\nнет',
                      textAlign: TextAlign.center,
                      style: AppStyle.manrope(
                        size: 20,
                        weight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            width: double.infinity,
            height: 226,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(AppColors.borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Количество договоров',
                  style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 50,
                              sections: [
                                PieChartSectionData(
                                  color: Color(AppColors.primaryLight),
                                  value: activeContracts.toDouble(),
                                  radius: 15,
                                  title: '',
                                ),
                                PieChartSectionData(
                                  color: Color(AppColors.greyLight),
                                  value: inactiveContracts.toDouble(),
                                  radius: 15,
                                  title: '',
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Всего',
                                style: AppStyle.manrope(
                                  size: 20,
                                  weight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalContracts',
                                style: AppStyle.manrope(
                                  size: 20,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(
                            Color(AppColors.primaryLight),
                            'Действующие',
                            activeContracts,
                          ),
                          const SizedBox(height: 30),
                          _buildLegendItem(
                            Colors.grey.shade400,
                            'Закрытые',
                            inactiveContracts,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return const SizedBox(
          height: 256,
          child: Center(child: Text('Нет данных')),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            label,
            style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          count.toString(),
          style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
        ),
      ],
    );
  }
}

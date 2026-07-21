import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/analytic_items_state.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class SalesPurchasesPieChart extends StatelessWidget {
  const SalesPurchasesPieChart({super.key});

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

          final sales = data.sales.toDouble();
          final purchases = data.purchases.toDouble();
          final total = sales + purchases;

          if (total == 0) {
            return Container(
              width: double.infinity,
              height: 256,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000809),
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                  BoxShadow(
                    color: Color(0x05000809),
                    blurRadius: 6,
                    offset: Offset(0, 0),
                  ),
                ],
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

          final salesPercentage = (sales / total) * 100;
          final purchasesPercentage = (purchases / total) * 100;

          return Container(
            width: double.infinity,
            height: 226,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000809),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
                BoxShadow(
                  color: Color(0x05000809),
                  blurRadius: 6,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Соотношение продаж и покупок',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
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
                              centerSpaceRadius: 46,
                              sections: [
                                PieChartSectionData(
                                  color: Color(AppColors.primary),
                                  value: salesPercentage,
                                  radius: 12,
                                  title: '',
                                ),
                                PieChartSectionData(
                                  color: Color(AppColors.primaryLight),
                                  value: purchasesPercentage,
                                  radius: 12,
                                  title: '',
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 6,
                            top: 4,
                            child: Text(
                              '${purchasesPercentage.toStringAsFixed(0)}%',
                              style: AppStyle.manrope(
                                size: 14,
                                weight: FontWeight.w500,
                                color: Color(AppColors.primaryLight),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            bottom: 4,
                            child: Text(
                              '${salesPercentage.toStringAsFixed(0)}%',
                              style: AppStyle.manrope(
                                size: 14,
                                weight: FontWeight.w500,
                                color: Color(AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(
                            Color(AppColors.primary),
                            'Продажи',
                            salesPercentage,
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            Color(AppColors.primaryLight),
                            'Покупки',
                            purchasesPercentage,
                          ),
                          const SizedBox(height: 12),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE6E9EE),
                          ),
                          const SizedBox(height: 10),
                          _buildLegendItem(
                            const Color(0x00000000),
                            'Всего',
                            100,
                            showDot: false,
                            isPercent: true,
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

  Widget _buildLegendItem(
    Color color,
    String label,
    double percent, {
    bool showDot = true,
    bool isPercent = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showDot)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 3),
            color: color,
          ),
        if (showDot) const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          isPercent ? '${percent.toStringAsFixed(0)}%' : percent.toString(),
          style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
        ),
      ],
    );
  }
}

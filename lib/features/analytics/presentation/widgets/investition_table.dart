import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/investment_dynamic_state.dart';

class InvestitionTable extends StatefulWidget {
  const InvestitionTable({super.key});

  @override
  State<InvestitionTable> createState() => _InvestitionTableState();
}

class _InvestitionTableState extends State<InvestitionTable> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '',
      decimalDigits: 0,
    );

    return BlocBuilder<InvestmentDynamicCubit, InvestmentDynamicState>(
      builder: (context, state) {
        if (state is InvestmentDynamicLoading) {
          return const SizedBox(
            height: 287,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is InvestmentDynamicError) {
          return SizedBox(
            height: 287,
            child: Center(child: Text('Ошибка: ${state.message}')),
          );
        }

        if (state is InvestmentDynamicLoaded) {
          // Переворачиваем периоды: новые сверху
          final periodsDesc = List.of(state.data.periods.reversed);
          final rowCount = periodsDesc.length;

          return SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Динамика инвестиций',
                        style: AppStyle.manrope(
                          size: 15,
                          weight: FontWeight.w400,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isExpanded)
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    border: TableBorder.all(
                      color: Color(AppColors.borderColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            child: Center(
                              child: Text(
                                'Дата',
                                style: AppStyle.manrope(
                                  size: 15,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                'Сумма, руб',
                                style: AppStyle.manrope(
                                  size: 15,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...List.generate(rowCount, (index) {
                        final month = periodsDesc[index].periodName;
                        final sum = periodsDesc[index].value.toInt();

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  month,
                                  style: AppStyle.manrope(
                                    size: 15,
                                    weight: FontWeight.w400,
                                    color: Color(AppColors.darkGrey),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  currencyFormatter.format(sum),
                                  style: AppStyle.manrope(
                                    size: 15,
                                    weight: FontWeight.w400,
                                    color: Color(AppColors.comfPayment),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
              ],
            ),
          );
        }

        return const SizedBox(
          height: 100,
          child: Center(child: Text('Нет данных')),
        );
      },
    );
  }
}

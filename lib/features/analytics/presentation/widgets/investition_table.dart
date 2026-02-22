import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/investment_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/investment_dynamic_state.dart';
import 'package:waypay_styles/waypay_styles.dart';

class InvestitionTable extends StatefulWidget {
  const InvestitionTable({super.key});

  @override
  State<InvestitionTable> createState() => _InvestitionTableState();
}

class _InvestitionTableState extends State<InvestitionTable> {
  bool _isExpanded = true;

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
                Container(
                  width: double.infinity,
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
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        overlayColor: MaterialStateProperty.all(
                          Colors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Динамика инвестиций',
                                  style: AppStyle.manrope(
                                    size: 16,
                                    weight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFF50555C),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isExpanded)
                        const Divider(
                          height: 0,
                          thickness: 1,
                          color: Color(0xFFE6E9EE),
                        ),
                      if (_isExpanded)
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(1),
                          },
                          border: const TableBorder(
                            horizontalInside:
                                BorderSide(color: Color(0xFFE6E9EE)),
                            top: BorderSide(color: Color(0xFFE6E9EE)),
                            bottom: BorderSide(color: Color(0xFFE6E9EE)),
                          ),
                          children: [
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Дата',
                                    style: AppStyle.manrope(
                                      size: 14,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Сумма',
                                    style: AppStyle.manrope(
                                      size: 14,
                                      weight: FontWeight.w500,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      month,
                                      style: AppStyle.manrope(
                                        size: 14,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF50555C),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      currencyFormatter.format(sum),
                                      style: AppStyle.manrope(
                                        size: 14,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF111111),
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

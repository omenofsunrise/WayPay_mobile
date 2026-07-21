import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/debt_dynamic_state.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class PaymentStatsTable extends StatefulWidget {
  const PaymentStatsTable({super.key});

  @override
  State<PaymentStatsTable> createState() => _PaymentStatsTableState();
}

class _PaymentStatsTableState extends State<PaymentStatsTable> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '',
      decimalDigits: 0,
    );

    return BlocBuilder<DebtDynamicCubit, DebtDynamicState>(
      builder: (context, state) {
        if (state is DebtDynamicLoading) {
          return const SizedBox(
            height: 487,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DebtDynamicError) {
          return SizedBox(
            height: 487,
            child: Center(child: Text('Ошибка: ${state.message}')),
          );
        }

        if (state is DebtDynamicLoaded) {
          final data = state.data;

          // Берём периоды и переворачиваем: новые сверху
          final overdue = List.of(data.debtDynamic.periods.reversed);
          final payment = List.of(data.paymentsDynamic.periods.reversed);

          // На всякий случай синхронизируем длины
          final rowCount = overdue.length < payment.length
              ? overdue.length
              : payment.length;

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
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Исполнение финансовых обязательств',
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
                            2: FlexColumnWidth(1),
                          },
                          border: const TableBorder(
                            horizontalInside: BorderSide(
                              color: Color(0xFFE6E9EE),
                            ),
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
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Просрочка',
                                    style: AppStyle.manrope(
                                      size: 14,
                                      weight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Платёж',
                                    style: AppStyle.manrope(
                                      size: 14,
                                      weight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            ...List.generate(rowCount, (index) {
                              final date = payment[index].periodName;
                              final overdueValue = overdue[index].value.toInt();
                              final paymentValue = payment[index].value.toInt();
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      date,
                                      style: AppStyle.manrope(
                                        size: 14,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF50555C),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      currencyFormatter.format(overdueValue),
                                      style: AppStyle.manrope(
                                        size: 14,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF111111),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      currencyFormatter.format(paymentValue),
                                      style: AppStyle.manrope(
                                        size: 14,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF111111),
                                      ),
                                      textAlign: TextAlign.right,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/analytics/presentation/cubit/debt_dynamic_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/debt_dynamic_state.dart';

class PaymentStatsTable extends StatefulWidget {
  const PaymentStatsTable({super.key});

  @override
  State<PaymentStatsTable> createState() => _PaymentStatsTableState();
}

class _PaymentStatsTableState extends State<PaymentStatsTable> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'ru_RU', symbol: '', decimalDigits: 0);

    return BlocBuilder<DebtDynamicCubit, DebtDynamicState>(
      builder: (context, state) {
        if (state is DebtDynamicLoading) {
          return const SizedBox(height: 487, child: Center(child: CircularProgressIndicator()));
        }

        if (state is DebtDynamicError) {
          return SizedBox(height: 487, child: Center(child: Text('Ошибка: ${state.message}')));
        }

        if (state is DebtDynamicLoaded) {
          final data = state.data;

          // Берём периоды и переворачиваем: новые сверху
          final overdue = List.of(data.debtDynamic.periods.reversed);
          final payment = List.of(data.paymentsDynamic.periods.reversed);

          // На всякий случай синхронизируем длины
          final rowCount = overdue.length < payment.length ? overdue.length : payment.length;

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
                        'Исполнение финансовых обязательств',
                        style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
                      ),
                      Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Table(
                  columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
                  border: TableBorder.all(color: Color(AppColors.borderColor), borderRadius: BorderRadius.circular(10)),
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          child: Center(
                            child: Text('Дата', style: AppStyle.manrope(size: 15, weight: FontWeight.w600)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              'Сумма просрочки, руб',
                              style: AppStyle.manrope(size: 15, weight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              'Сумма платежей, руб',
                              style: AppStyle.manrope(size: 15, weight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...List.generate(
                      _isExpanded ? rowCount : (rowCount > 0 ? 1 : 0), // в свернутом виде показываем 1 свежую строку
                      (index) {
                        final date = payment[index].periodName;
                        final overdueValue = overdue[index].value.toInt();
                        final paymentValue = payment[index].value.toInt();
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  date,
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
                                  currencyFormatter.format(overdueValue),
                                  style: AppStyle.manrope(
                                    size: 15,
                                    weight: FontWeight.w400,
                                    color: Color(AppColors.comfPayment),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  currencyFormatter.format(paymentValue),
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
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return const SizedBox(height: 100, child: Center(child: Text('Нет данных')));
      },
    );
  }
}

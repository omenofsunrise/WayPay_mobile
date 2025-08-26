import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/profile/presentation/cubit/payment_stats_cubit.dart';

class PaymentStatsProfileTable extends StatefulWidget {
  final int? employeeId;

  const PaymentStatsProfileTable({super.key, this.employeeId});

  @override
  State<PaymentStatsProfileTable> createState() => _PaymentStatsProfileTableState();
}

class _PaymentStatsProfileTableState extends State<PaymentStatsProfileTable> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final cubit = context.read<PaymentStatsCubit>();
    const months = 12;
    if (widget.employeeId != null) {
      cubit.loadStatsByEmployeeId(employeeId: widget.employeeId!, months: months);
    } else {
      cubit.loadStats(months: months);
    }
  }

  String _monthName(int month) {
    const names = ['', 'Янв', 'Фев', 'Март', 'Апр', 'Май', 'Июнь', 'Июль', 'Авг', 'Сент', 'Окт', 'Нояб', 'Дек'];
    return (month >= 1 && month <= 12) ? names[month] : '';
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'ru_RU', symbol: '', decimalDigits: 0);

    return BlocBuilder<PaymentStatsCubit, PaymentStatsState>(
      builder: (context, state) {
        if (state is PaymentStatsLoading) {
          return const SizedBox(height: 487, child: Center(child: CircularProgressIndicator()));
        }

        if (state is PaymentStatsError) {
          return SizedBox(height: 487, child: Center(child: Text('Ошибка: ${state.message}')));
        }

        if (state is PaymentStatsLoaded) {
          final statsDesc = List.of(state.stats.reversed); // новые сверху
          final rowCount = statsDesc.length;

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
                      Text('Статистика платежей', style: AppStyle.manrope(size: 15, weight: FontWeight.w400)),
                      Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isExpanded)
                  Table(
                    columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
                    border: TableBorder.all(
                      color: Color(AppColors.borderColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 4),
                            child: Center(
                              child: Text('Месяц', style: AppStyle.manrope(size: 15, weight: FontWeight.w600)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                'Подтвержденные, руб',
                                style: AppStyle.manrope(size: 15, weight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                              child: Text(
                                'Неподтвержденные, руб',
                                style: AppStyle.manrope(size: 15, weight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...List.generate(rowCount, (index) {
                        final item = statsDesc[index];
                        final date = _monthName(item.month);
                        final confirmed = item.assumed.toInt();
                        final unconfirmed = item.notAssumed.toInt();

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
                                  currencyFormatter.format(confirmed),
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
                                  currencyFormatter.format(unconfirmed),
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

        return const SizedBox(height: 100, child: Center(child: Text('Нет данных')));
      },
    );
  }
}

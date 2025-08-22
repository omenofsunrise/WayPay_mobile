import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay/features/analytics/presentation/cubit/sell_info_state.dart';

class PaymentDynamicTable extends StatefulWidget {
  const PaymentDynamicTable({super.key});

  @override
  State<PaymentDynamicTable> createState() => _PaymentDynamicTableState();
}

class _PaymentDynamicTableState extends State<PaymentDynamicTable> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'ru_RU', symbol: '', decimalDigits: 0);

    return BlocBuilder<SellInfoCubit, SellInfoState>(
      builder: (context, state) {
        if (state is SellInfoLoading) {
          return const SizedBox(height: 287, child: Center(child: CircularProgressIndicator()));
        }

        if (state is SellInfoError) {
          return SizedBox(height: 287, child: Center(child: Text('Ошибка: ${state.message}')));
        }

        if (state is SellInfoLoaded) {
          final sells = state.data.sellsSum.periods;
          final purchases = state.data.purchasesSum.periods;
          final cash = state.data.cash.periods;

          final periodsDesc = List.generate(
            sells.length,
            (i) => {
              'period': sells[i].periodName,
              'sell': sells[i].value.toInt(),
              'purchase': purchases[i].value.toInt(),
              'cash': cash[i].value.toInt(),
            },
          ).reversed.toList();

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
                        'Динамика продаж, покупок и остатка в кассе',
                        style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
                      ),
                      Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                    3: FlexColumnWidth(),
                  },
                  border: TableBorder.all(color: Color(AppColors.borderColor), borderRadius: BorderRadius.circular(10)),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
                      children: [
                        _headerCell('Дата'),
                        _headerCell('Продажи'),
                        _headerCell('Покупки'),
                        _headerCell('Касса'),
                      ],
                    ),
                    ...List.generate(_isExpanded ? rowCount : (rowCount > 0 ? 1 : 0), (index) {
                      final row = periodsDesc[index];
                      return TableRow(
                        children: [
                          _dataCell(row['period'] as String, color: AppColors.darkGrey),
                          _dataCell(currencyFormatter.format(row['sell']), color: AppColors.comfPayment),
                          _dataCell(currencyFormatter.format(row['purchase']), color: AppColors.comfPayment),
                          _dataCell(currencyFormatter.format(row['cash']), color: AppColors.comfPayment),
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

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(text, style: AppStyle.manrope(size: 15, weight: FontWeight.w600)),
      ),
    );
  }

  Widget _dataCell(String text, {required int color}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: AppStyle.manrope(size: 15, weight: FontWeight.w400, color: Color(color)),
        ),
      ),
    );
  }
}

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
    final currency = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '',
      decimalDigits: 0,
    );

    return BlocBuilder<SellInfoCubit, SellInfoState>(
      builder: (context, state) {
        Widget? body;

        if (_isExpanded) {
          if (state is SellInfoLoading) {
            body = const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state is SellInfoError) {
            body = Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('Ошибка: ${state.message}')),
            );
          } else if (state is SellInfoLoaded) {
            final sells = state.data.sellsSum.periods;
            final purchases = state.data.purchasesSum.periods;
            final cash = state.data.cash.periods;

            final rows = List.generate(
              sells.length,
              (i) => {
                'period': sells[i].periodName,
                'sell': sells[i].value.toInt(),
                'purchase': purchases[i].value.toInt(),
                'cash': cash[i].value.toInt(),
              },
            ).reversed.toList();

            body = Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
              },
              border: TableBorder.all(
                color: Color(AppColors.borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              children: [
                TableRow(
                  children: [
                    _headerCell('Дата'),
                    _headerCell('Продажи'),
                    _headerCell('Покупки'),
                    _headerCell('Касса'),
                  ],
                ),
                ...rows.map(
                  (r) => TableRow(
                    children: [
                      _dataCell(
                        r['period'] as String,
                        color: AppColors.darkGrey,
                      ),
                      _dataCell(
                        currency.format(r['sell']),
                        color: AppColors.comfPayment,
                      ),
                      _dataCell(
                        currency.format(r['purchase']),
                        color: AppColors.comfPayment,
                      ),
                      _dataCell(
                        currency.format(r['cash']),
                        color: AppColors.comfPayment,
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            body = const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('Нет данных')),
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // заголовок секции (аккордеон)
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Динамика продаж, покупок и остатка в кассе',
                      style: AppStyle.manrope(
                        size: 15,
                        weight: FontWeight.w400,
                      ),
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
            const SizedBox(height: 12),
            if (body != null) body,
          ],
        );
      },
    );
  }

  Widget _headerCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: Text(
        text,
        style: AppStyle.manrope(size: 15, weight: FontWeight.w600),
      ),
    ),
  );

  Widget _dataCell(String text, {required int color}) => Padding(
    padding: const EdgeInsets.all(8),
    child: Center(
      child: Text(
        text,
        style: AppStyle.manrope(
          size: 15,
          weight: FontWeight.w400,
          color: Color(color),
        ),
      ),
    ),
  );
}

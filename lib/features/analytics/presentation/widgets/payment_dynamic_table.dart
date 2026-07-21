import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/sell_info_cubit.dart';
import 'package:waypay_mobile/features/analytics/presentation/cubit/sell_info_state.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

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
        Widget? table;

        if (_isExpanded) {
          if (state is SellInfoLoading) {
            table = const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state is SellInfoError) {
            table = Padding(
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

            table = Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: Color(0xFFE6E9EE)),
                top: BorderSide(color: Color(0xFFE6E9EE)),
                bottom: BorderSide(color: Color(0xFFE6E9EE)),
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
                        color: const Color(0xFF50555C),
                      ),
                      _dataCell(
                        currency.format(r['sell']),
                        color: const Color(0xFF111111),
                      ),
                      _dataCell(
                        currency.format(r['purchase']),
                        color: const Color(0xFF111111),
                      ),
                      _dataCell(
                        currency.format(r['cash']),
                        color: const Color(0xFF111111),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            table = const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('Нет данных')),
            );
          }
        }

        return Container(
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
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Динамика продаж и покупок',
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
              if (table != null) table,
            ],
          ),
        );
      },
    );
  }

  Widget _headerCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Text(
      text,
      style: AppStyle.manrope(size: 14, weight: FontWeight.w500),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _dataCell(String text, {required Color color}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Text(
      text,
      style: AppStyle.manrope(size: 14, weight: FontWeight.w400, color: color),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

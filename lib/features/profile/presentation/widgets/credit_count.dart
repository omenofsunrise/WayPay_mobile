import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/features/profile/presentation/cubit/credit_stats_cubit.dart';

class CreditCount extends StatefulWidget {
  final int? employeeId;

  const CreditCount({super.key, this.employeeId});

  @override
  State<CreditCount> createState() => _CreditCountState();
}

class _CreditCountState extends State<CreditCount> {
  String selectedPeriod = 'за текущий год';
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final cubit = context.read<CreditStatsCubit>();
    final months = selectedPeriod == 'за текущий год' ? 12 : 12;

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
    final NumberFormat numberFormatter = NumberFormat.decimalPattern('ru_RU');
    return BlocBuilder<CreditStatsCubit, CreditStatsState>(
      builder: (context, state) {
        if (state is CreditStatsLoading) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (state is CreditStatsError) {
          return SizedBox(height: 200, child: Center(child: Text('Ошибка: ${state.message}')));
        }
        if (state is CreditStatsLoaded) {
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
                      Text('Количество договоров', style: AppStyle.manrope(size: 15, weight: FontWeight.w400)),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Color(AppColors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
                  border: TableBorder.all(color: Color(AppColors.borderColor), borderRadius: BorderRadius.circular(10)),
                  children: [
                    TableRow(children: [_buildHeaderCell('Месяц'), _buildHeaderCell('Количество')]),
                    ...List.generate(_isExpanded ? rowCount : (rowCount > 0 ? 1 : 0), (index) {
                      final e = statsDesc[index];
                      return TableRow(
                        children: [
                          _buildDataCell(_monthName(e.month), isMonth: true),
                          _buildDataCell(numberFormatter.format(e.count)),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(text, style: AppStyle.manrope(size: 15, weight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isMonth = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          text,
          style: AppStyle.manrope(
            size: 15,
            weight: FontWeight.w400,
            color: isMonth ? Color(AppColors.darkGrey) : Color(AppColors.comfPayment),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_model.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class InvestorPayoutTable extends StatefulWidget {
  final int investorId;

  const InvestorPayoutTable({super.key, required this.investorId});

  @override
  State<InvestorPayoutTable> createState() => _InvestorPayoutTableState();
}

class _InvestorPayoutTableState extends State<InvestorPayoutTable> {
  late Future<List<InvestorPayoutModel>> _payoutsFuture;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _payoutsFuture = getIt<InvestorsRemoteDataSource>()
        .getInvestorPayoutsByInvestorId(widget.investorId);
  }

  String formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  String formatAmount(double amount) =>
      NumberFormat('#,##0', 'ru_RU').format(amount);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InvestorPayoutModel>>(
      future: _payoutsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Ошибка: ${snapshot.error}')),
          );
        }

        final payouts = snapshot.data ?? [];
        final hasPayouts = payouts.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'История выплат',
                    style: AppStyle.manrope(size: 15, weight: FontWeight.w400),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Color(AppColors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_isExpanded)
              hasPayouts
                  ? Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      border: TableBorder.all(
                        color: Color(AppColors.borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      children: [
                        TableRow(
                          children: [
                            _buildHeaderCell('Дата выплаты'),
                            _buildHeaderCell('Выплатил'),
                            _buildHeaderCell('Выплата, руб'),
                          ],
                        ),
                        ...payouts.map(
                          (p) => TableRow(
                            children: [
                              _buildDataCell(formatDate(p.payoutDate)),
                              _buildDataCell(p.employeeFullName),
                              _buildDataCell('${formatAmount(p.amount)} ₽'),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Text(
                        'Выплат нет',
                        style: AppStyle.manrope(
                          size: 15,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: AppStyle.manrope(size: 15, weight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          text,
          style: AppStyle.manrope(
            size: 15,
            weight: FontWeight.w400,
            color: Color(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

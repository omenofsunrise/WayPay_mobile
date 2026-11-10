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
              child: WayPaySectionHeader(
                title: 'История выплат',
                action: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(AppColors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isExpanded)
              hasPayouts
                  ? Column(
                      children: payouts
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: WayPayOperationTile(
                                title: '${formatAmount(p.amount)} ₽',
                                subtitle:
                                    '${formatDate(p.payoutDate)} · ${p.employeeFullName}',
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : const WayPayEmptyState(title: 'Выплат нет'),
          ],
        );
      },
    );
  }
}

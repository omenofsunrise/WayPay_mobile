import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_credit_table.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_payout_table.dart';

class InvestorReportScreen extends StatefulWidget {
  const InvestorReportScreen({super.key, required this.initialInvestor});

  final InvestorsModel initialInvestor;

  @override
  State<InvestorReportScreen> createState() => _InvestorReportScreenState();
}

class _InvestorReportScreenState extends State<InvestorReportScreen> {
  late InvestorsModel selectedInvestor;
  Map<String, dynamic>? reportData;
  String? error;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedInvestor = widget.initialInvestor;
    _loadInvestorAndReport(selectedInvestor.id);
  }

  Future<void> _loadInvestorAndReport(int investorId) async {
    setState(() {
      isLoading = true;
      reportData = null;
      error = null;
    });
    try {
      final investor = await getIt<InvestorsRemoteDataSource>().getInvestorById(
        investorId,
      );
      final report = await getIt<InvestorsRemoteDataSource>().getInvestorReport(
        investorId,
      );
      if (!mounted) return;
      setState(() {
        selectedInvestor = investor;
        reportData = report;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Ошибка загрузки: $e';
        isLoading = false;
      });
    }
  }

  String formatDate(String? date) {
    if (date == null) return '-';
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String formatNumber(dynamic value) {
    if (value == null) return '-';
    final num? number = num.tryParse(value.toString());
    if (number == null) return value.toString();
    return NumberFormat('#,##0', 'ru_RU').format(number);
  }

  Widget _buildCard(String title, String value, String icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, width: 48, height: 48),
            const SizedBox(height: 12),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.primary),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(AppColors.primary),
        elevation: 0,
        title: Text(
          'Отчёт: ${selectedInvestor.nickname}',
          style: AppStyle.medium20.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reportData == null
                  ? Center(
                      child: Text(
                        error ?? 'Нет данных',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                            children: [
                              if (reportData?['isCompany'] == false) ...[
                                _buildCard(
                                  'Инвестиция',
                                  '${formatNumber(reportData?['investment'])} ₽',
                                  SvgIcons.investition,
                                ),
                                _buildCard(
                                  'Незакрытые договоры',
                                  formatNumber(
                                    reportData?['activeCreditsAmount'],
                                  ),
                                  SvgIcons.credits,
                                ),
                                _buildCard(
                                  'Доля инвестора',
                                  '${selectedInvestor.investorPie} %',
                                  SvgIcons.investorPercent,
                                ),
                                _buildCard(
                                  'Доход инвестора',
                                  '${formatNumber(reportData?['investorIncome'])} ₽',
                                  SvgIcons.investorCahs,
                                ),
                                _buildCard(
                                  'Собственный доход',
                                  '${formatNumber(reportData?['allSelfIncome'])} ₽',
                                  SvgIcons.debtSelf,
                                ),
                                _buildCard(
                                  'Общий доход',
                                  '${formatNumber(reportData?['allSelfIncome'] + reportData?['investorIncome'])} ₽',
                                  SvgIcons.companyAmount,
                                ),
                                _buildCard(
                                  'Касса',
                                  '${formatNumber(reportData?['balance'])} ₽',
                                  SvgIcons.cash,
                                ),
                                _buildCard(
                                  'Просрочка',
                                  '${formatNumber(reportData?['delinquencyAmount'])} ₽',
                                  SvgIcons.delay,
                                ),
                                _buildCard(
                                  'Доходы по платежам в текущем месяце',
                                  '${formatNumber(reportData?['paymentIncome'])} ₽',
                                  SvgIcons.debt,
                                ),
                              ],
                              if (reportData?['isCompany'] == true) ...[
                                _buildCard(
                                  'Инвестиция',
                                  '${formatNumber(reportData?['investment'])} ₽',
                                  SvgIcons.investition,
                                ),
                                _buildCard(
                                  'Незакрытые договоры',
                                  formatNumber(
                                    reportData?['activeCreditsAmount'],
                                  ),
                                  SvgIcons.credits,
                                ),
                                _buildCard(
                                  'Доход компании',
                                  '${formatNumber(reportData?['investorIncome'])} ₽',
                                  SvgIcons.companyAmount,
                                ),
                                _buildCard(
                                  'Доход от инвестора',
                                  '${formatNumber(reportData?['allSelfIncome'])} ₽',
                                  SvgIcons.investorAmount,
                                ),
                                _buildCard(
                                  'Касса',
                                  '${formatNumber(reportData?['balance'])} ₽',
                                  SvgIcons.cash,
                                ),
                                _buildCard(
                                  'Просрочка',
                                  '${formatNumber(reportData?['delinquencyAmount'])} ₽',
                                  SvgIcons.delay,
                                ),
                                _buildCard(
                                  'Доходы по платежам в текущем месяце',
                                  '${formatNumber(reportData?['paymentIncome'])} ₽',
                                  SvgIcons.debt,
                                ),
                              ],
                            ],
                          ),
                          InvestorPayoutTable(
                            investorId: widget.initialInvestor.id,
                          ),
                          const SizedBox(height: 16),
                          InvestorCreditsWidget(
                            investorId: widget.initialInvestor.id,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

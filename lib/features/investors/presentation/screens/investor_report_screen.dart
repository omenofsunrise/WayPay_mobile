import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay/core/di/dependency_injection.dart';
import 'package:waypay/core/network/token_storage.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/app_drawer/app_drawer.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay/features/investors/data/models/investors_model.dart';
import 'package:waypay/features/investors/presentation/widgets/investor_payout_dialog.dart';
import 'package:waypay/features/investors/presentation/widgets/investor_picker_modal.dart';
import 'package:waypay/routes/routes.dart';

class InvestorReportScreen extends StatefulWidget {
  const InvestorReportScreen({super.key});

  @override
  State<InvestorReportScreen> createState() => _InvestorReportScreenState();
}

class _InvestorReportScreenState extends State<InvestorReportScreen> {
  final _tokenStorage = TokenStorage();
  InvestorsModel? selectedInvestor;
  Map<String, dynamic>? reportData;
  String? error;
  bool isLoadingReport = false;

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.userTypeSelectionScreen.toName);
    }
  }

  Future<void> _loadReport(int investorId) async {
    setState(() {
      isLoadingReport = true;
      reportData = null;
      error = null;
    });

    try {
      final data = await getIt<InvestorsRemoteDataSource>().getInvestorReport(
        investorId,
      );
      setState(() {
        reportData = data;
        isLoadingReport = false;
      });
    } catch (e) {
      setState(() {
        error = 'Ошибка загрузки отчета: $e';
        isLoadingReport = false;
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
    return NumberFormat('#,##0').format(number);
  }

  Widget _buildCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Color(AppColors.primary), size: 28),
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
      drawer: AppDrawer(),
      backgroundColor: const Color(AppColors.primaryLight),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(AppColors.primaryLight),
        elevation: 0,
        title: Text(
          'Отчет инвестора',
          style: AppStyle.medium20.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => context.pushNamed(Routes.profileScreen.toName),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(AppColors.primaryLight),
            padding: const EdgeInsets.all(16),
            child: DefaultButton(
              text: selectedInvestor == null
                  ? 'Выбрать инвестора'
                  : 'Выбран: ${selectedInvestor!.nickname}',
              onPressed: () async {
                final result = await showDialog<InvestorsModel>(
                  context: context,
                  builder: (_) => const InvestorPickerModal(),
                );
                if (result != null) {
                  setState(() => selectedInvestor = result);
                  _loadReport(result.id);
                }
              },
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: isLoadingReport
                  ? const Center(child: CircularProgressIndicator())
                  : reportData == null
                  ? const Center(
                      child: Text('Выберите инвестора для просмотра отчета'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DefaultButton(
                            text: 'Выплатить инвестору',
                            color: Color(AppColors.primary),
                            onPressed: () async {
                              final isCompany =
                                  reportData?['isCompany'] == true;
                              final income =
                                  (reportData?[isCompany
                                              ? 'investorIncome'
                                              : 'investorIncome'] ??
                                          0.0)
                                      as num;
                              final balance =
                                  (reportData?['balance'] ?? 0.0) as num;
                              final maxAmount = income < balance
                                  ? income
                                  : balance;

                              final amount = await showDialog<double>(
                                context: context,
                                builder: (_) => InvestorPayoutDialog(
                                  maxAmount: maxAmount.toDouble(),
                                  income: income.toDouble(),
                                  balance: balance.toDouble(),
                                ),
                              );

                              if (amount != null) {
                                try {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  final payoutResponse =
                                      await getIt<InvestorsRemoteDataSource>()
                                          .createInvestorPayout(
                                            investorId: selectedInvestor!.id,
                                            amount: amount,
                                          );

                                  Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Выплата ${payoutResponse.amount.toStringAsFixed(0)} ₽ успешно проведена!',
                                      ),
                                    ),
                                  );

                                  _loadReport(selectedInvestor!.id);
                                } catch (e) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Ошибка выплаты: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1,
                            children: [
                              // Дата создания
                              _buildCard(
                                'Создан',
                                formatDate(reportData?['createdAt']),
                                Icons.calendar_today,
                              ),

                              // Если компания
                              if (reportData?['isCompany'] == true) ...[
                                _buildCard(
                                  'Инвестиция',
                                  '${formatNumber(reportData?['investment'])} ₽',
                                  Icons.attach_money,
                                ),
                                _buildCard(
                                  'Активные договоры',
                                  formatNumber(
                                    reportData?['activeCreditsAmount'],
                                  ),
                                  Icons.assignment,
                                ),
                                _buildCard(
                                  'Доход компании',
                                  '${formatNumber(reportData?['investorIncome'])} ₽',
                                  Icons.trending_up,
                                ),
                                _buildCard(
                                  'Касса',
                                  '${formatNumber(reportData?['balance'])} ₽',
                                  Icons.account_balance_wallet,
                                ),
                              ],

                              // Если НЕ компания
                              if (reportData?['isCompany'] != true) ...[
                                _buildCard(
                                  'Доля инвестора',
                                  '${selectedInvestor?.investorPie ?? '-'}%',
                                  Icons.pie_chart,
                                ),
                                _buildCard(
                                  'Инвестиция',
                                  '${formatNumber(reportData?['investment'])} ₽',
                                  Icons.attach_money,
                                ),
                                _buildCard(
                                  'Доход инвестора',
                                  '${formatNumber(reportData?['investorIncome'])} ₽',
                                  Icons.trending_up,
                                ),
                                _buildCard(
                                  'Собственный доход',
                                  '${formatNumber(reportData?['selfIncome'])} ₽',
                                  Icons.trending_up,
                                ),
                                _buildCard(
                                  'Общий доход',
                                  '${formatNumber((reportData?['investorIncome'] ?? 0) + (reportData?['selfIncome'] ?? 0))} ₽',
                                  Icons.summarize,
                                ),
                                _buildCard(
                                  'Касса',
                                  '${formatNumber(reportData?['balance'])} ₽',
                                  Icons.account_balance_wallet,
                                ),
                                _buildCard(
                                  'Незакрытые договоры',
                                  formatNumber(
                                    reportData?['activeCreditsAmount'],
                                  ),
                                  Icons.assignment,
                                ),
                              ],
                            ],
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

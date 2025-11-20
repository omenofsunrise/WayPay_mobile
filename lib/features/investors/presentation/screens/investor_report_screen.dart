import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
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
    if (value == null) return '—';
    final num? number = num.tryParse(value.toString());
    if (number == null) return value.toString();
    return NumberFormat('#,##0', 'ru_RU').format(number);
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildCard(String title, String value, String icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000809), blurRadius: 4)],
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
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(
                title: 'Детали инвестора',
                showBackButton: true,
                showNotifications: true,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : reportData == null
                        ? Center(
                            child: Text(
                              error ?? 'Нет данных',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(AppColors.darkGrey),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                _loadInvestorAndReport(selectedInvestor.id),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _NicknameCard(name: selectedInvestor.fullName),
                                  const SizedBox(height: 16),
                                  _AnalyticsGrid(metrics: _buildMetrics()),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_MetricData> _buildMetrics() {
    final isCompany = reportData?['isCompany'] == true;
    final metrics = <_MetricData>[
      _MetricData(
        title: 'Касса',
        value: '${formatNumber(reportData?['balance'] ?? selectedInvestor.balance)} ₽',
        icon: SvgIcons.cash,
      ),
      _MetricData(
        title: 'Активные договоры',
        value: formatNumber(reportData?['activeCreditsAmount']),
        icon: SvgIcons.credits,
      ),
      _MetricData(
        title: 'Инвестиции',
        value: '${formatNumber(reportData?['investment'] ?? selectedInvestor.investmentAmount)} ₽',
        icon: SvgIcons.investition,
      ),
      _MetricData(
        title: 'Общий доход',
        value:
            '${formatNumber(_asDouble(reportData?['allSelfIncome']) + _asDouble(reportData?['investorIncome']))} ₽',
        icon: SvgIcons.companyAmount,
      ),
      _MetricData(
        title: 'Просрочка',
        value: '${formatNumber(reportData?['delinquencyAmount'])} ₽',
        icon: SvgIcons.delay,
        valueColor: const Color(AppColors.red),
      ),
    ];

    if (!isCompany) {
      metrics.insert(
        4,
        _MetricData(
          title: 'Доход инвестора',
          value: '${formatNumber(reportData?['investorIncome'])} ₽',
          icon: SvgIcons.investorCahs,
        ),
      );
      metrics.insert(
        5,
        _MetricData(
          title: 'Доход компании',
          value: '${formatNumber(reportData?['allSelfIncome'])} ₽',
          icon: SvgIcons.companyAmount,
        ),
      );
    } else {
      metrics.insert(
        4,
        _MetricData(
          title: 'Доход компании',
          value: '${formatNumber(reportData?['investorIncome'])} ₽',
          icon: SvgIcons.companyAmount,
        ),
      );
      metrics.insert(
        5,
        _MetricData(
          title: 'Доход от инвестора',
          value: '${formatNumber(reportData?['allSelfIncome'])} ₽',
          icon: SvgIcons.investorAmount,
        ),
      );
    }

    return metrics;
  }
}

class _NicknameCard extends StatelessWidget {
  const _NicknameCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x05000809),
            offset: Offset(0, 0),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Никнейм',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 24 / 14,
              color: Color(AppColors.darkGrey),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 24 / 16,
              color: Color(AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _MetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor = const Color(AppColors.black),
  });

  final String title;
  final String value;
  final String icon;
  final Color valueColor;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000809),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x05000809),
            offset: Offset(0, 0),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F4F1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: SvgPicture.asset(metric.icon, width: 28, height: 28),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            metric.title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 20 / 14,
              color: Color(AppColors.darkGrey),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 22,
              height: 1.1,
              color: metric.valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

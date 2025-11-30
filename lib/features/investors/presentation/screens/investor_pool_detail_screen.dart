import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';

class InvestorPoolDetailScreen extends StatefulWidget {
  const InvestorPoolDetailScreen({super.key, required this.pool});

  final InvestorPoolModel pool;

  @override
  State<InvestorPoolDetailScreen> createState() =>
      _InvestorPoolDetailScreenState();
}

class _InvestorPoolDetailScreenState extends State<InvestorPoolDetailScreen> {
  Map<String, dynamic>? _reportData;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final report = await getIt<InvestorsRemoteDataSource>()
          .getInvestorPoolReport(widget.pool.id);
      if (!mounted) return;
      setState(() {
        _reportData = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  final NumberFormat _numberFormatter = NumberFormat('#,##0', 'ru_RU');

  String _formatCurrency(dynamic value) {
    if (value == null) return '—';
    return '${_formatNumber(value)}₽';
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '—';
    final number = _asDouble(value);
    return _numberFormatter.format(number);
  }

  List<_MetricData> _buildMetrics() {
    final data = _reportData ?? {};
    final totalIncome =
        _asDouble(data['investorIncome']) + _asDouble(data['allSelfIncome']);
    return [
      _MetricData(
        title: 'Касса',
        value: _formatCurrency(data['balance']),
        icon: SvgIcons.cash,
      ),
      _MetricData(
        title: 'Активные договоры',
        value: _formatNumber(data['activeCreditsAmount']),
        icon: SvgIcons.docIcon,
      ),
      _MetricData(
        title: 'Инвестиции',
        value: _formatCurrency(data['investment']),
        icon: SvgIcons.investition,
      ),
      _MetricData(
        title: 'Общий доход',
        value: _formatCurrency(totalIncome),
        icon: SvgIcons.companyAmount,
      ),
      _MetricData(
        title: 'Текущий доход',
        value: _formatCurrency(data['paymentIncome']),
        icon: SvgIcons.investorAmount,
      ),
      _MetricData(
        title: 'Текущий доход пула',
        value: _formatCurrency(data['investorPaymentIncome']),
        icon: SvgIcons.moneyIcon,
      ),
      _MetricData(
        title: 'Ожидаемый доход',
        value: _formatCurrency(data['selfPaymentIncome']),
        icon: SvgIcons.moneyIcon,
      ),
      _MetricData(
        title: 'Просрочка',
        value: _formatCurrency(data['delinquencyAmount']),
        icon: SvgIcons.delay,
        valueColor: const Color(AppColors.red),
      ),
    ];
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
                title: 'Детали пула',
                showBackButton: true,
                showNotifications: true,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _reportData == null
                        ? Center(
                            child: Text(
                              _error ?? 'Нет данных',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(AppColors.darkGrey),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReport,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _NicknameCard(
                                    name: (_reportData?['nickName'] ??
                                            widget.pool.name)
                                        .toString(),
                                  ),
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
  static const double _cardHeight = 170;

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
                  height: _cardHeight,
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

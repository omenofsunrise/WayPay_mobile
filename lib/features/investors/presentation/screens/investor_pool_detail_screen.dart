import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';

class InvestorPoolDetailScreen extends StatefulWidget {
  const InvestorPoolDetailScreen({super.key, required this.pool});

  final InvestorPoolModel pool;

  @override
  State<InvestorPoolDetailScreen> createState() =>
      _InvestorPoolDetailScreenState();
}

class _InvestorPoolDetailScreenState extends State<InvestorPoolDetailScreen> {
  Map<String, dynamic>? _reportData;
  List<InvestorsModel> _investors = [];
  String? _error;
  String? _investorsError;
  bool _isLoading = false;
  bool _isInvestorsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
    _loadInvestors();
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

  Future<void> _loadInvestors() async {
    setState(() {
      _isInvestorsLoading = true;
      _investorsError = null;
    });
    try {
      final response = await getIt<InvestorsRemoteDataSource>().getInvestors(
        page: 1,
        pageSize: 50,
        poolId: widget.pool.id,
      );
      if (!mounted) return;
      setState(() {
        _investors = response.investors;
        _isInvestorsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _investorsError = 'Ошибка загрузки инвесторов: $e';
        _isInvestorsLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadReport(),
      _loadInvestors(),
    ]);
  }

  Future<void> _handleAddInvestment(InvestorsModel investor) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _AddInvestmentDialog(name: investor.fullName),
    );
    if (!mounted || amount == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await getIt<InvestorsRemoteDataSource>().addInvestment(
        id: investor.id,
        amount: amount,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Инвестиция добавлена')),
      );
      await _loadInvestors();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
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
    const hintGreen = Color(0x4D32BA8F);
    const overdueBg = Color(0x4DFF8E42);
    return [
      _MetricData(
        title: 'Касса',
        value: _formatCurrency(data['balance']),
        icon: SvgIcons.cash,
        highlighted: true,
      ),
      _MetricData(
        title: 'Активные договоры',
        value: _formatNumber(data['activeCreditsAmount']),
        icon: SvgIcons.credits,
        highlighted: true,
      ),
      _MetricData(
        title: 'Инвестиции',
        value: _formatCurrency(data['investment']),
        icon: SvgIcons.investition,
        backgroundColor: hintGreen,
      ),
      _MetricData(
        title: 'Общий доход',
        value: _formatCurrency(totalIncome),
        icon: SvgIcons.rub,
        backgroundColor: hintGreen,
      ),
      _MetricData(
        title: 'Текущий доход',
        value: _formatCurrency(data['paymentIncome']),
        icon: SvgIcons.investorCahs,
        backgroundColor: hintGreen,
      ),
      _MetricData(
        title: 'Текущий доход пула',
        value: _formatCurrency(data['investorPaymentIncome']),
        icon: SvgIcons.companyAmount,
        backgroundColor: hintGreen,
      ),
      _MetricData(
        title: 'Ожидаемый доход',
        value: _formatCurrency(data['selfPaymentIncome']),
        icon: SvgIcons.schedule,
        backgroundColor: hintGreen,
      ),
      _MetricData(
        title: 'Просрочка',
        value: _formatCurrency(data['delinquencyAmount']),
        icon: SvgIcons.delay,
        valueColor: const Color(AppColors.red),
        backgroundColor: overdueBg,
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
                showNotifications: false,
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
                            color: Color(AppColors.uiBorder),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PoolNameCard(
                                name: (_reportData?['name'] ??
                                        widget.pool.name)
                                    .toString(),
                              ),
                              const SizedBox(height: 16),
                              _AnalyticsGrid(metrics: _buildMetrics()),
                              const SizedBox(height: 20),
                              const Text(
                                'Инвесторы',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(AppColors.uiBorder),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_isInvestorsLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_investorsError != null)
                                Center(
                                  child: Text(
                                    _investorsError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(AppColors.uiBorder),
                                    ),
                                  ),
                                )
                              else if (_investors.isEmpty)
                                const Center(
                                  child: Text(
                                    'Инвесторы не найдены',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(AppColors.uiBorder),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: _investors
                                      .map(
                                        (investor) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _PoolInvestorCard(
                                            investor: investor,
                                            onAddInvestment: () =>
                                                _handleAddInvestment(investor),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
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

class _PoolNameCard extends StatelessWidget {
  const _PoolNameCard({required this.name});

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
            'Название пула',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 24 / 14,
              color: Color(AppColors.uiBorder),
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

class _PoolInvestorCard extends StatelessWidget {
  const _PoolInvestorCard({
    required this.investor,
    required this.onAddInvestment,
  });

  final InvestorsModel investor;
  final VoidCallback onAddInvestment;

  String _formatCurrency(num value) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ID: ${investor.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(investor.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              investor.fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _InfoColumn(
              label: 'Инвестиции',
              value: _formatCurrency(investor.investmentAmount),
            ),
            const SizedBox(height: 12),
            DefaultButton(
              text: 'Добавить инвестицию',
              isPrimary: true,
              onPressed: onAddInvestment,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddInvestmentDialog extends StatefulWidget {
  const _AddInvestmentDialog({required this.name});

  final String name;

  @override
  State<_AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<_AddInvestmentDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      setState(() => _errorText = 'Введите корректную сумму');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Добавить инвестицию',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(AppColors.uiBorder),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Введите сумму',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DefaultButton(
                      text: 'Отмена',
                      isPrimary: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DefaultButton(
                      text: 'Добавить',
                      isPrimary: true,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    this.backgroundColor,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final String icon;
  final Color valueColor;
  final Color? backgroundColor;
  final bool highlighted;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 171),
      child: Container(
        constraints: const BoxConstraints(minHeight: 128),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    metric.backgroundColor ??
                    (metric.highlighted
                        ? const Color(0x4D14BFDB)
                        : const Color(0xFFE4F4F1)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: SvgPicture.asset(metric.icon, width: 20, height: 20),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              metric.title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: 0,
                color: Color(AppColors.uiBorder),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              metric.value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 1.2,
                letterSpacing: 0,
                color: metric.valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(AppColors.uiBorder),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
        ),
      ],
    );
  }
}

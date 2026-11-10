import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_contribution_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_model.dart';
import 'package:waypay_mobile/features/investors/data/models/reinvestment_model.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_form_sheet.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_investment_dialog.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_payout_dialog.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_report_screen.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_response_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';

class InvestorPoolDetailScreen extends StatefulWidget {
  const InvestorPoolDetailScreen({super.key, required this.pool});

  final InvestorPoolModel pool;

  @override
  State<InvestorPoolDetailScreen> createState() =>
      _InvestorPoolDetailScreenState();
}

class _InvestorPoolDetailScreenState extends State<InvestorPoolDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _operationKeys = [
    'payouts',
    'credits',
    'contributions',
    'reinvestments',
  ];

  late final TabController _operationsController;
  Map<String, dynamic>? _reportData;
  List<InvestorsModel> _investors = [];
  List<InvestorPayoutModel> _payouts = [];
  List<InvestorContributionModel> _contributions = [];
  List<ReinvestmentModel> _reinvestments = [];
  List<CreditModel> _credits = [];
  String? _error;
  String? _investorsError;
  bool _isLoading = false;
  bool _isInvestorsLoading = false;
  String _operationsTab = 'payouts';

  @override
  void initState() {
    super.initState();
    _operationsController = TabController(length: 4, vsync: this)
      ..addListener(_handleOperationsTabChanged);
    _loadReport();
    _loadInvestors();
    _loadOperations();
  }

  void _handleOperationsTabChanged() {
    final nextTab = _operationKeys[_operationsController.index];
    if (!mounted || _operationsTab == nextTab) return;
    setState(() => _operationsTab = nextTab);
  }

  @override
  void dispose() {
    _operationsController
      ..removeListener(_handleOperationsTabChanged)
      ..dispose();
    super.dispose();
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
    await Future.wait([_loadReport(), _loadInvestors(), _loadOperations()]);
  }

  Future<void> _loadOperations() async {
    try {
      final source = getIt<InvestorsRemoteDataSource>();
      final results = await Future.wait<dynamic>([
        source.getInvestorPayoutsByPoolId(widget.pool.id),
        source.getInvestorContributions(
          poolId: widget.pool.id,
          page: 1,
          pageSize: 100,
        ),
        source.getReinvestments(widget.pool.id, page: 1, pageSize: 100),
        getIt<CreditRemoteDataSource>().getCredits(
          GetCreditsQuery(
            page: 1,
            pageSize: 100,
            investorPoolId: widget.pool.id,
          ),
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _payouts = results[0] as List<InvestorPayoutModel>;
        _contributions = (results[1] as InvestorContributionsPage).items;
        _reinvestments = results[2] as List<ReinvestmentModel>;
        _credits = (results[3] as CreditResponseModel).items;
      });
    } catch (_) {
      // Основной отчёт остаётся доступным, даже если одна из историй временно
      // не загрузилась.
    }
  }

  Future<void> _createInvestor() async {
    final saved = await showInvestorFormSheet(context, poolId: widget.pool.id);
    if (!mounted || saved != true) return;
    showAppMessage(
      context,
      'Инвестор добавлен в пул',
      type: AppMessageType.success,
    );
    await _refreshAll();
  }

  Future<void> _reinvestPool() async {
    final confirmed = await showWayPayConfirmDialog(
      context,
      title: 'Реинвестировать доход?',
      message: 'Текущий доход инвесторов пула будет добавлен к инвестициям.',
      confirmText: 'Реинвестировать',
    );
    if (confirmed != true) return;
    try {
      await getIt<InvestorsRemoteDataSource>().reinvestInvestorPool(
        widget.pool.id,
      );
      if (!mounted) return;
      showAppMessage(
        context,
        'Реинвестиция выполнена',
        type: AppMessageType.success,
      );
      await _refreshAll();
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _payoutInvestor(InvestorsModel investor) async {
    final income = investor.investorIncome ?? 0;
    final balance = investor.balance;
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => InvestorPayoutDialog(
        maxAmount: income > 0 ? income : balance,
        income: income,
        balance: balance,
      ),
    );
    if (!mounted || amount == null) return;
    try {
      await getIt<InvestorsRemoteDataSource>().createInvestorPayout(
        investorId: investor.id,
        amount: amount,
        payoutSource: income > 0 ? 'income' : 'investment',
      );
      if (!mounted) return;
      showAppMessage(context, 'Выплата создана', type: AppMessageType.success);
      await _refreshAll();
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _deletePayout(InvestorPayoutModel payout) async {
    try {
      await getIt<InvestorsRemoteDataSource>().deleteInvestorPayout(payout.id);
      await _refreshAll();
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _contributionAction(
    InvestorContributionModel contribution,
    String action,
  ) async {
    try {
      if (action == 'edit') {
        final controller = TextEditingController(
          text: contribution.amount.toStringAsFixed(0),
        );
        final saved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => WayPayModal(
            title: 'Изменить инвестицию',
            onClose: () => Navigator.pop(dialogContext, false),
            onPrimary: () => Navigator.pop(dialogContext, true),
            child: ModalTextField(
              controller: controller,
              label: 'Сумма, ₽',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
        );
        final amount = double.tryParse(
          controller.text.trim().replaceAll(',', '.'),
        );
        controller.dispose();
        if (saved != true || amount == null || amount <= 0) return;
        await getIt<InvestorsRemoteDataSource>().updateInvestmentContribution(
          id: contribution.id,
          amount: amount,
          date: contribution.date,
        );
      } else {
        await getIt<InvestorsRemoteDataSource>()
            .makeInvestmentContributionAction(contribution.id, action);
      }
      await _refreshAll();
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _handleAddInvestment(InvestorsModel investor) async {
    final investment = await showDialog<InvestorInvestmentDraft>(
      context: context,
      builder: (_) => InvestorInvestmentDialog(
        investorName: investor.fullName.isEmpty
            ? investor.nickname
            : investor.fullName,
      ),
    );
    if (!mounted || investment == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await getIt<InvestorsRemoteDataSource>().addInvestment(
        id: investor.id,
        amount: investment.amount,
        date: investment.date,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppMessage(
        context,
        'Инвестиция добавлена',
        type: AppMessageType.success,
      );
      await _loadInvestors();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
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
                    ? const WayPayLoadingState()
                    : _reportData == null
                    ? WayPayErrorState(
                        message: _error ?? 'Нет данных',
                        onRetry: _refreshAll,
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WayPayEntityHeaderCard(
                                title:
                                    (_reportData?['name'] ?? widget.pool.name)
                                        .toString(),
                                subtitle: 'Инвестиционный пул',
                                icon: const Icon(
                                  Icons.account_balance_outlined,
                                  color: Color(AppColors.primary),
                                ),
                                metricLabel: 'Касса пула',
                                metricValue:
                                    '${NumberFormat.decimalPattern('ru_RU').format(_asDouble(_reportData?['balance'] ?? widget.pool.balance))} ₽',
                              ),
                              const SizedBox(height: 16),
                              _AnalyticsGrid(metrics: _buildMetrics()),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: DefaultButton(
                                      text: 'Добавить инвестора',
                                      isPrimary: true,
                                      onPressed: _createInvestor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: DefaultButton(
                                      text: 'Реинвестировать',
                                      isPrimary: false,
                                      onPressed: _reinvestPool,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const WayPaySectionHeader(title: 'Инвесторы'),
                              const SizedBox(height: 8),
                              if (_isInvestorsLoading)
                                const WayPayLoadingState()
                              else if (_investorsError != null)
                                WayPayErrorState(
                                  message: _investorsError,
                                  onRetry: _loadInvestors,
                                )
                              else if (_investors.isEmpty)
                                const WayPayEmptyState(
                                  title: 'Инвесторы не найдены',
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
                                            onPayout: () =>
                                                _payoutInvestor(investor),
                                            onOpen: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    InvestorReportScreen(
                                                      initialInvestor: investor,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 20),
                              const WayPaySectionHeader(
                                title: 'История операций',
                              ),
                              const SizedBox(height: 10),
                              CustomTabSwitcher(
                                controller: _operationsController,
                                isScrollable: true,
                                tabs: const [
                                  'Выплаты',
                                  'Договоры',
                                  'Инвестиции',
                                  'Реинвест.',
                                ],
                              ),
                              const SizedBox(height: 10),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: KeyedSubtree(
                                  key: ValueKey(_operationsTab),
                                  child: _buildOperations(),
                                ),
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

  Widget _buildOperations() {
    if (_operationsTab == 'payouts') {
      if (_payouts.isEmpty) {
        return const WayPayEmptyState(title: 'Выплат нет');
      }
      return Column(
        children: _payouts
            .map(
              (item) => WayPayOperationTile(
                title: '${_formatNumber(item.amount)} ₽',
                subtitle:
                    '${DateFormat('dd.MM.yyyy').format(item.payoutDate)} · ${item.employeeFullName}',
                trailing: IconButton(
                  onPressed: () => _deletePayout(item),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ),
            )
            .toList(),
      );
    }
    if (_operationsTab == 'contributions') {
      if (_contributions.isEmpty) {
        return const WayPayEmptyState(title: 'Инвестиций нет');
      }
      return Column(
        children: _contributions
            .map(
              (item) => WayPayOperationTile(
                title: '${_formatNumber(item.amount)} ₽',
                subtitle:
                    '${DateFormat('dd.MM.yyyy').format(item.date)} · ${item.investorNickname ?? 'Инвестор'}',
                trailing: WayPayOverflowMenuButton<String>(
                  title: 'Действия с инвестицией',
                  onSelected: (action) => _contributionAction(item, action),
                  items: [
                    const WayPayActionSheetItem(
                      value: 'edit',
                      label: 'Редактировать',
                      icon: Icons.edit_outlined,
                    ),
                    if (!item.confirmed)
                      const WayPayActionSheetItem(
                        value: 'confirm',
                        label: 'Подтвердить',
                        icon: Icons.check_circle_outline,
                      ),
                    const WayPayActionSheetItem(
                      value: 'reject',
                      label: 'Удалить',
                      icon: Icons.delete_outline,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }
    if (_operationsTab == 'credits') {
      if (_credits.isEmpty) {
        return const WayPayEmptyState(title: 'Договоров нет');
      }
      return Column(
        children: _credits
            .map(
              (item) => WayPayOperationTile(
                title: item.name?.isNotEmpty == true
                    ? 'Договор №${item.name}'
                    : 'Договор №${item.id}',
                subtitle:
                    '${item.clientFullName} · ${_formatNumber(item.rest)} ₽ остаток',
              ),
            )
            .toList(),
      );
    }
    if (_reinvestments.isEmpty) {
      return const WayPayEmptyState(title: 'Реинвестиций нет');
    }
    return Column(
      children: _reinvestments
          .map(
            (item) => WayPayOperationTile(
              title: '${_formatNumber(item.amount)} ₽',
              subtitle:
                  '${DateFormat('dd.MM.yyyy').format(item.date)} · ${item.investorNickname}',
            ),
          )
          .toList(),
    );
  }
}

class _PoolInvestorCard extends StatelessWidget {
  const _PoolInvestorCard({
    required this.investor,
    required this.onAddInvestment,
    required this.onPayout,
    required this.onOpen,
  });

  final InvestorsModel investor;
  final VoidCallback onAddInvestment;
  final VoidCallback onPayout;
  final VoidCallback onOpen;

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
    return WayPayEntityCard(
      title: investor.nickname,
      subtitle: investor.fullName.isEmpty ? null : investor.fullName,
      details: [
        WayPayInfoItem(
          label: 'Инвестиции',
          value: _formatCurrency(investor.investmentAmount),
        ),
        WayPayInfoItem(
          label: 'Добавлен',
          value: _formatDate(investor.createdAt),
        ),
      ],
      actions: [
        WayPayCardAction(
          icon: Icons.add_circle_outline,
          label: 'Инвестиция',
          onPressed: onAddInvestment,
        ),
        WayPayCardAction(
          icon: Icons.payments_outlined,
          label: 'Выплатить',
          onPressed: onPayout,
        ),
      ],
      onTap: onOpen,
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
                  child: WayPayMetricCard(
                    title: metric.title,
                    value: metric.value,
                    valueColor: metric.valueColor,
                    iconBackground:
                        metric.backgroundColor ??
                        (metric.highlighted
                            ? const Color(0x4D14BFDB)
                            : const Color(0xFFE4F4F1)),
                    icon: SvgPicture.asset(metric.icon, width: 20, height: 20),
                  ),
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

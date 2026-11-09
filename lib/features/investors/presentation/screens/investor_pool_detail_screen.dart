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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Реинвестировать доход?'),
        content: const Text(
          'Текущий доход инвесторов пула будет добавлен к инвестициям.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Реинвестировать'),
          ),
        ],
      ),
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
          builder: (dialogContext) => AlertDialog(
            title: const Text('Изменить инвестицию'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Сумма, ₽'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Сохранить'),
              ),
            ],
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
    final investment = await showDialog<_PoolInvestmentDraft>(
      context: context,
      builder: (_) => _AddInvestmentDialog(name: investor.fullName),
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
                                name: (_reportData?['name'] ?? widget.pool.name)
                                    .toString(),
                                balance: _asDouble(
                                  _reportData?['balance'] ??
                                      widget.pool.balance,
                                ),
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
                              const Text(
                                'История операций',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              CustomTabSwitcher(
                                controller: _operationsController,
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
        return const _PoolEmptyOperations(text: 'Выплат нет');
      }
      return Column(
        children: _payouts
            .map(
              (item) => _PoolOperationCard(
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
        return const _PoolEmptyOperations(text: 'Инвестиций нет');
      }
      return Column(
        children: _contributions
            .map(
              (item) => _PoolOperationCard(
                title: '${_formatNumber(item.amount)} ₽',
                subtitle:
                    '${DateFormat('dd.MM.yyyy').format(item.date)} · ${item.investorNickname ?? 'Инвестор'}',
                trailing: PopupMenuButton<String>(
                  onSelected: (action) => _contributionAction(item, action),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Редактировать'),
                    ),
                    if (!item.confirmed)
                      const PopupMenuItem(
                        value: 'confirm',
                        child: Text('Подтвердить'),
                      ),
                    const PopupMenuItem(
                      value: 'reject',
                      child: Text(
                        'Удалить',
                        style: TextStyle(color: Colors.red),
                      ),
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
        return const _PoolEmptyOperations(text: 'Договоров нет');
      }
      return Column(
        children: _credits
            .map(
              (item) => _PoolOperationCard(
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
      return const _PoolEmptyOperations(text: 'Реинвестиций нет');
    }
    return Column(
      children: _reinvestments
          .map(
            (item) => _PoolOperationCard(
              title: '${_formatNumber(item.amount)} ₽',
              subtitle:
                  '${DateFormat('dd.MM.yyyy').format(item.date)} · ${item.investorNickname}',
            ),
          )
          .toList(),
    );
  }
}

class _PoolNameCard extends StatelessWidget {
  const _PoolNameCard({required this.name, required this.balance});

  final String name;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 4),
            blurRadius: 16,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: Color(AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(AppColors.black),
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Инвестиционный пул',
                      style: TextStyle(
                        color: Color(AppColors.uiBorder),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Касса пула',
            style: const TextStyle(
              color: Color(AppColors.uiBorder),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat.decimalPattern('ru_RU').format(balance)} ₽',
            style: const TextStyle(
              color: Color(AppColors.black),
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              investor.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (investor.fullName.isNotEmpty)
                              Text(
                                investor.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(AppColors.uiBorder),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(AppColors.uiBorder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoColumn(
                          label: 'Инвестиции',
                          value: _formatCurrency(investor.investmentAmount),
                        ),
                      ),
                      Expanded(
                        child: _InfoColumn(
                          label: 'Добавлен',
                          value: _formatDate(investor.createdAt),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F4)),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onAddInvestment,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Инвестиция'),
                ),
              ),
              Container(width: 1, height: 24, color: const Color(0xFFEEF1F4)),
              Expanded(
                child: TextButton.icon(
                  onPressed: onPayout,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Выплатить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoolInvestmentDraft {
  const _PoolInvestmentDraft(this.amount, this.date);

  final double amount;
  final DateTime date;
}

class _AddInvestmentDialog extends StatefulWidget {
  const _AddInvestmentDialog({required this.name});

  final String name;

  @override
  State<_AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<_AddInvestmentDialog> {
  final _controller = TextEditingController();
  DateTime _date = DateTime.now();
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
    Navigator.pop(context, _PoolInvestmentDraft(value, _date));
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
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Дата инвестиции'),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(_date)),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    locale: const Locale('ru', 'RU'),
                  );
                  if (selected != null && mounted) {
                    setState(() => _date = selected);
                  }
                },
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

class _PoolOperationCard extends StatelessWidget {
  const _PoolOperationCard({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _PoolEmptyOperations extends StatelessWidget {
  const _PoolEmptyOperations({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(AppColors.uiBorder)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_contribution_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_payout_model.dart';
import 'package:waypay_mobile/features/investors/presentation/screens/investor_cash_position_screen.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_form_sheet.dart';
import 'package:waypay_mobile/features/investors/presentation/widgets/investor_payout_dialog.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_response_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class InvestorReportScreen extends StatefulWidget {
  const InvestorReportScreen({super.key, required this.initialInvestor});

  final InvestorsModel initialInvestor;

  @override
  State<InvestorReportScreen> createState() => _InvestorReportScreenState();
}

class _InvestorReportScreenState extends State<InvestorReportScreen>
    with SingleTickerProviderStateMixin {
  static const _operationKeys = ['payouts', 'credits', 'contributions'];

  late InvestorsModel selectedInvestor;
  late final TabController _operationsController;
  Map<String, dynamic>? reportData;
  List<InvestorPayoutModel> payouts = [];
  List<InvestorContributionModel> contributions = [];
  List<CreditModel> credits = [];
  String? error;
  bool isLoading = false;
  String operationsTab = 'payouts';

  @override
  void initState() {
    super.initState();
    _operationsController = TabController(length: 3, vsync: this)
      ..addListener(_handleOperationsTabChanged);
    selectedInvestor = widget.initialInvestor;
    _loadInvestorAndReport(selectedInvestor.id);
  }

  void _handleOperationsTabChanged() {
    final nextTab = _operationKeys[_operationsController.index];
    if (!mounted || operationsTab == nextTab) return;
    setState(() => operationsTab = nextTab);
  }

  @override
  void dispose() {
    _operationsController
      ..removeListener(_handleOperationsTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadInvestorAndReport(int investorId) async {
    setState(() {
      isLoading = true;
      reportData = null;
      error = null;
    });
    try {
      final source = getIt<InvestorsRemoteDataSource>();
      final results = await Future.wait<dynamic>([
        source.getInvestorById(investorId),
        source.getInvestorReport(investorId),
        source.getInvestorPayoutsByInvestorId(investorId),
        source.getInvestorContributions(
          investorId: investorId,
          page: 1,
          pageSize: 100,
        ),
        getIt<CreditRemoteDataSource>().getCreditsByInvestorId(
          investorId,
          GetCreditsQuery(page: 1, pageSize: 100),
        ),
      ]);
      final investor = results[0] as InvestorsModel;
      final report = results[1] as Map<String, dynamic>;
      final loadedPayouts = results[2] as List<InvestorPayoutModel>;
      final loadedContributions = results[3] as InvestorContributionsPage;
      final loadedCredits = results[4] as CreditResponseModel;
      if (!mounted) return;
      setState(() {
        selectedInvestor = investor;
        reportData = report;
        payouts = loadedPayouts;
        contributions = loadedContributions.items;
        credits = loadedCredits.items;
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

  Future<void> _editInvestor() async {
    final saved = await showInvestorFormSheet(
      context,
      investor: selectedInvestor,
    );
    if (saved == true && mounted) {
      showAppMessage(
        context,
        'Инвестор обновлён',
        type: AppMessageType.success,
      );
      await _loadInvestorAndReport(selectedInvestor.id);
    }
  }

  Future<void> _createPayout() async {
    final income = _asDouble(reportData?['investorIncome']);
    final balance = _asDouble(
      reportData?['balance'] ?? selectedInvestor.balance,
    );
    final source = await showWayPayBottomSheet<String>(
      context: context,
      builder: (sheetContext) => WayPayBottomSheet(
        title: 'Источник выплаты',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WayPayEntityTile(
              title: 'Из дохода',
              subtitle: '${formatNumber(income)} ₽ доступно',
              leading: const WayPayIconBadge(icon: Icons.trending_up),
              showChevron: true,
              onTap: () => Navigator.pop(sheetContext, 'income'),
            ),
            const Divider(height: 1),
            WayPayEntityTile(
              title: 'Из инвестиции',
              subtitle: '${formatNumber(balance)} ₽ в кассе',
              leading: const WayPayIconBadge(
                icon: Icons.account_balance_wallet_outlined,
              ),
              showChevron: true,
              onTap: () => Navigator.pop(sheetContext, 'investment'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    final maxAmount = source == 'income' ? income : balance;
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => InvestorPayoutDialog(
        maxAmount: maxAmount,
        income: income,
        balance: balance,
      ),
    );
    if (!mounted || amount == null) return;
    try {
      await getIt<InvestorsRemoteDataSource>().createInvestorPayout(
        investorId: selectedInvestor.id,
        amount: amount,
        payoutSource: source,
      );
      if (!mounted) return;
      showAppMessage(context, 'Выплата создана', type: AppMessageType.success);
      await _loadInvestorAndReport(selectedInvestor.id);
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _deletePayout(InvestorPayoutModel payout) async {
    final confirmed = await showWayPayConfirmDialog(
      context,
      title: 'Удалить выплату?',
      message: '${formatNumber(payout.amount)} ₽',
      confirmText: 'Удалить',
      isDestructive: true,
    );
    if (confirmed != true) return;
    try {
      await getIt<InvestorsRemoteDataSource>().deleteInvestorPayout(payout.id);
      await _loadInvestorAndReport(selectedInvestor.id);
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _editContribution(InvestorContributionModel contribution) async {
    final amountController = TextEditingController(
      text: contribution.amount.toStringAsFixed(0),
    );
    final dateController = TextEditingController(
      text: DateFormat('dd.MM.yyyy').format(contribution.date),
    );
    var date = contribution.date;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => WayPayModal(
          title: 'Редактирование инвестиции',
          onClose: () => Navigator.pop(dialogContext, false),
          onPrimary: () => Navigator.pop(dialogContext, true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTextField(
                controller: amountController,
                label: 'Сумма, ₽',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 14),
              ModalTextField(
                controller: dateController,
                label: 'Дата',
                readOnly: true,
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: dialogContext,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    locale: const Locale('ru', 'RU'),
                  );
                  if (selected != null) {
                    setDialogState(() {
                      date = selected;
                      dateController.text = DateFormat(
                        'dd.MM.yyyy',
                      ).format(selected);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) {
      amountController.dispose();
      dateController.dispose();
      return;
    }
    final amount = double.tryParse(
      amountController.text.trim().replaceAll(',', '.'),
    );
    amountController.dispose();
    dateController.dispose();
    if (amount == null || amount <= 0) return;
    try {
      await getIt<InvestorsRemoteDataSource>().updateInvestmentContribution(
        id: contribution.id,
        amount: amount,
        date: date,
      );
      await _loadInvestorAndReport(selectedInvestor.id);
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
    if (action == 'edit') {
      await _editContribution(contribution);
      return;
    }
    if (action == 'reject') {
      final confirmed = await showWayPayConfirmDialog(
        context,
        title: 'Удалить инвестицию?',
        message: '${formatNumber(contribution.amount)} ₽',
        confirmText: 'Удалить',
        isDestructive: true,
      );
      if (confirmed != true) return;
    }
    try {
      await getIt<InvestorsRemoteDataSource>().makeInvestmentContributionAction(
        contribution.id,
        action,
      );
      await _loadInvestorAndReport(selectedInvestor.id);
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _shareInvestor() async {
    try {
      final result = await getIt<InvestorsRemoteDataSource>()
          .createInvestorShareLink(selectedInvestor.id);
      final token = result['token']?.toString();
      final apiUri = Uri.parse(ApiConfig.apiBaseUrl);
      final webOrigin = Uri(scheme: apiUri.scheme, host: apiUri.host).origin;
      final link =
          (result['url'] ?? result['link'])?.toString() ??
          (token == null || token.isEmpty
              ? null
              : '$webOrigin/investor-public?token=$token');
      if (link == null || link.isEmpty) throw Exception('ссылка не получена');
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        showAppMessage(
          context,
          'Временная ссылка скопирована',
          type: AppMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  Future<void> _showAgreement() async {
    try {
      final agreement = await getIt<InvestorsRemoteDataSource>()
          .getInvestorAgreement(selectedInvestor.id);
      if (!mounted) return;
      await showWayPayBottomSheet<void>(
        context: context,
        builder: (_) => WayPayBottomSheet(
          title: 'Договор с инвестором',
          footer: SizedBox(
            width: double.infinity,
            child: DefaultButton(
              text: 'Поделиться PDF',
              isPrimary: true,
              onPressed: () => _shareAgreementPdf(agreement),
            ),
          ),
          child: WayPayInfoCard(
            showShadow: false,
            fields: agreement.entries
                .map(
                  (entry) => WayPayInfoField(
                    label: _agreementLabel(entry.key),
                    value: entry.value?.toString() ?? '—',
                  ),
                )
                .toList(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
      }
    }
  }

  String _agreementLabel(String key) => switch (key) {
    'city' => 'Город',
    'investorDate' => 'Дата',
    'investorName' => 'Инвестор',
    'investment' => 'Инвестиция',
    'investorPie' => 'Доля инвестора',
    'companyPie' => 'Доля компании',
    'investorMonths' => 'Срок',
    'directorName' => 'Директор',
    _ => key,
  };

  Future<pw.Font> _pdfFont() async {
    final data = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    return pw.Font.ttf(data);
  }

  Future<void> _shareAgreementPdf(Map<String, dynamic> agreement) async {
    final font = await _pdfFont();
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (_) => [
          pw.Header(level: 0, text: 'Договор с инвестором'),
          ...agreement.entries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Text(_agreementLabel(entry.key))),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Text(
                      entry.value?.toString() ?? '—',
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'Договор_${selectedInvestor.nickname}.pdf',
    );
  }

  Future<void> _shareReportPdf() async {
    final font = await _pdfFont();
    final document = pw.Document();
    final metrics = _buildMetrics();
    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (_) => [
          pw.Header(level: 0, text: 'Отчёт инвестора'),
          pw.Text(selectedInvestor.nickname),
          pw.Text(selectedInvestor.fullName),
          pw.SizedBox(height: 16),
          ...metrics.map(
            (metric) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(metric.title)),
                  pw.Text(metric.value),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Выплаты'),
          if (payouts.isEmpty)
            pw.Text('Выплат нет')
          else
            ...payouts.map(
              (payout) => pw.Text(
                '${DateFormat('dd.MM.yyyy').format(payout.payoutDate)} — ${formatNumber(payout.amount)} ₽ — ${payout.employeeFullName}',
              ),
            ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'Отчёт_${selectedInvestor.nickname}.pdf',
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
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const WayPayLoadingState()
                    : reportData == null
                    ? WayPayErrorState(
                        message: error ?? 'Нет данных',
                        onRetry: () =>
                            _loadInvestorAndReport(selectedInvestor.id),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            _loadInvestorAndReport(selectedInvestor.id),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WayPayEntityHeaderCard(
                                title: selectedInvestor.nickname,
                                subtitle: selectedInvestor.fullName,
                                icon: const Icon(
                                  Icons.person_outline,
                                  color: Color(AppColors.primary),
                                ),
                                metricLabel: 'Доступно в кассе',
                                metricValue:
                                    '${NumberFormat.decimalPattern('ru_RU').format(_asDouble(reportData?['balance'] ?? selectedInvestor.balance))} ₽',
                                badge: selectedInvestor.contractEndDate == null
                                    ? null
                                    : WayPayStatusBadge(
                                        text:
                                            'Договор до ${DateFormat('dd.MM.yyyy').format(selectedInvestor.contractEndDate!)}',
                                        tone: WayPayStatusTone.info,
                                      ),
                              ),
                              const SizedBox(height: 12),
                              _InvestorActions(
                                onEdit: _editInvestor,
                                onPayout: _createPayout,
                                onShare: _shareInvestor,
                                onAgreement: _showAgreement,
                                onExport: _shareReportPdf,
                                onCash: _openCashPositions,
                              ),
                              const SizedBox(height: 16),
                              _AnalyticsGrid(metrics: _buildMetrics()),
                              const SizedBox(height: 20),
                              const WayPaySectionHeader(
                                title: 'История операций',
                              ),
                              const SizedBox(height: 12),
                              CustomTabSwitcher(
                                controller: _operationsController,
                                tabs: const [
                                  'Выплаты',
                                  'Договоры',
                                  'Инвестиции',
                                ],
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: KeyedSubtree(
                                  key: ValueKey(operationsTab),
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
    if (operationsTab == 'payouts') {
      if (payouts.isEmpty) return const WayPayEmptyState(title: 'Выплат нет');
      return Column(
        children: payouts
            .map(
              (payout) => WayPayOperationTile(
                title: '${formatNumber(payout.amount)} ₽',
                subtitle:
                    '${formatDate(payout.payoutDate.toIso8601String())} · ${payout.employeeFullName}',
                status: payout.payoutSource == 'investment'
                    ? 'Из инвестиции'
                    : 'Из дохода',
                trailing: IconButton(
                  onPressed: () => _deletePayout(payout),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ),
            )
            .toList(),
      );
    }
    if (operationsTab == 'credits') {
      if (credits.isEmpty) {
        return const WayPayEmptyState(title: 'Договоров нет');
      }
      return Column(
        children: credits
            .map(
              (credit) => WayPayOperationTile(
                title: credit.name?.isNotEmpty == true
                    ? 'Договор №${credit.name}'
                    : 'Договор №${credit.id}',
                subtitle:
                    '${credit.clientFullName} · ${DateFormat('dd.MM.yyyy').format(credit.creditDate)}',
                status: '${formatNumber(credit.rest)} ₽ остаток',
              ),
            )
            .toList(),
      );
    }
    if (contributions.isEmpty) {
      return const WayPayEmptyState(title: 'Инвестиций нет');
    }
    return Column(
      children: contributions
          .map(
            (contribution) => WayPayOperationTile(
              title: '${formatNumber(contribution.amount)} ₽',
              subtitle: DateFormat('dd.MM.yyyy').format(contribution.date),
              status: contribution.confirmed
                  ? 'Подтверждено'
                  : 'Не подтверждено',
              trailing: WayPayOverflowMenuButton<String>(
                title: 'Действия с инвестицией',
                onSelected: (action) =>
                    _contributionAction(contribution, action),
                items: [
                  const WayPayActionSheetItem(
                    value: 'edit',
                    label: 'Редактировать',
                    icon: Icons.edit_outlined,
                  ),
                  if (!contribution.confirmed)
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

  Future<void> _openCashPositions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvestorCashPositionScreen(
          investorId: selectedInvestor.id,
          investorName: selectedInvestor.fullName,
        ),
      ),
    );
    if (!mounted) return;
    // Перевод кассы меняет отчёт инвестора — перечитываем.
    await _loadInvestorAndReport(selectedInvestor.id);
  }

  List<_MetricData> _buildMetrics() {
    final isCompany = reportData?['isCompany'] == true;
    const hintGreen = Color(0x4D32BA8F);
    final metrics = <_MetricData>[
      _MetricData(
        title: 'Касса',
        value:
            '${formatNumber(reportData?['balance'] ?? selectedInvestor.balance)} ₽',
        icon: SvgIcons.cash,
        highlighted: true,
      ),
      _MetricData(
        title: 'Активные договоры',
        value: formatNumber(reportData?['activeCreditsAmount']),
        icon: SvgIcons.credits,
        highlighted: true,
      ),
      _MetricData(
        title: 'Инвестиции',
        value:
            '${formatNumber(reportData?['investment'] ?? selectedInvestor.investmentAmount)} ₽',
        icon: SvgIcons.investition,
        backgroundColor: hintGreen,
      ),
      _MetricData(
        title: 'Общий доход',
        value:
            '${formatNumber(_asDouble(reportData?['allSelfIncome']) + _asDouble(reportData?['investorIncome']))} ₽',
        icon: SvgIcons.rub,
        backgroundColor: hintGreen,
      ),
      _MetricData(
        title: 'Просрочка',
        value: '${formatNumber(reportData?['delinquencyAmount'])} ₽',
        icon: SvgIcons.delay,
        valueColor: const Color(AppColors.red),
        backgroundColor: const Color(0x4DFF8E42),
      ),
    ];

    final incomeMetrics = isCompany
        ? [
            _MetricData(
              title: 'Доход компании',
              value: '${formatNumber(reportData?['investorIncome'])} ₽',
              icon: SvgIcons.companyAmount,
              backgroundColor: hintGreen,
            ),
            _MetricData(
              title: 'Доход от инвестора',
              value: '${formatNumber(reportData?['allSelfIncome'])} ₽',
              icon: SvgIcons.investorCahs,
              backgroundColor: hintGreen,
            ),
          ]
        : [
            _MetricData(
              title: 'Доход инвестора',
              value: '${formatNumber(reportData?['investorIncome'])} ₽',
              icon: SvgIcons.investorCahs,
              backgroundColor: hintGreen,
            ),
            _MetricData(
              title: 'Доход компании',
              value: '${formatNumber(reportData?['allSelfIncome'])} ₽',
              icon: SvgIcons.companyAmount,
              backgroundColor: hintGreen,
            ),
          ];

    metrics.insertAll(4, incomeMetrics);

    return metrics;
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
                  child: WayPayMetricCard.asset(
                    circleColor:
                        metric.backgroundColor ??
                        (metric.highlighted
                            ? const Color(0x4D14BFDB)
                            : const Color(0xFFE4F4F1)),
                    iconAsset: metric.icon,
                    title: metric.title,
                    value: metric.value,
                    valueColor: metric.valueColor,
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
  final bool highlighted;
  final Color? backgroundColor;
}

class _InvestorActions extends StatelessWidget {
  const _InvestorActions({
    required this.onEdit,
    required this.onPayout,
    required this.onShare,
    required this.onAgreement,
    required this.onExport,
    required this.onCash,
  });

  final VoidCallback onEdit;
  final VoidCallback onPayout;
  final VoidCallback onShare;
  final VoidCallback onAgreement;
  final VoidCallback onExport;
  final VoidCallback onCash;

  @override
  Widget build(BuildContext context) {
    return WayPaySurfaceCard(
      padding: const EdgeInsets.all(12),
      showShadow: false,
      showBorder: true,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DefaultButton(
              text: 'Выплатить инвестору',
              isPrimary: true,
              onPressed: onPayout,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: WayPayActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Касса',
                    onTap: onCash,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: WayPayActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Изменить',
                    onTap: onEdit,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: WayPayActionTile(
                    icon: Icons.link,
                    label: 'Ссылка',
                    onTap: onShare,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: WayPayActionTile(
                    icon: Icons.description_outlined,
                    label: 'Договор',
                    onTap: onAgreement,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: WayPayActionTile(
                    icon: Icons.ios_share_outlined,
                    label: 'PDF',
                    onTap: onExport,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

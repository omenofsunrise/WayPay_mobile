import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/config/api_config.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/widgets/dashboard_info_mini_card.dart';
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

class _InvestorReportScreenState extends State<InvestorReportScreen> {
  late InvestorsModel selectedInvestor;
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
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Источник выплаты',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Из дохода'),
                subtitle: Text('${formatNumber(income)} ₽ доступно'),
                onTap: () => Navigator.pop(sheetContext, 'income'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Из инвестиции'),
                subtitle: Text('${formatNumber(balance)} ₽ в кассе'),
                onTap: () => Navigator.pop(sheetContext, 'investment'),
              ),
            ],
          ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить выплату?'),
        content: Text('${formatNumber(payout.amount)} ₽'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
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
    var date = contribution.date;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Редактирование инвестиции'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Сумма, ₽'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Дата'),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(date)),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: dialogContext,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    locale: const Locale('ru', 'RU'),
                  );
                  if (selected != null) setDialogState(() => date = selected);
                },
              ),
            ],
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
      ),
    );
    if (saved != true) {
      amountController.dispose();
      return;
    }
    final amount = double.tryParse(
      amountController.text.trim().replaceAll(',', '.'),
    );
    amountController.dispose();
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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Удалить инвестицию?'),
          content: Text('${formatNumber(contribution.amount)} ₽'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
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
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Договор с инвестором',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  ...agreement.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _agreementLabel(entry.key),
                              style: const TextStyle(
                                color: Color(AppColors.uiBorder),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value?.toString() ?? '—',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: DefaultButton(
                      text: 'Поделиться PDF',
                      isPrimary: true,
                      onPressed: () => _shareAgreementPdf(agreement),
                    ),
                  ),
                ],
              ),
            ),
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
                    ? const Center(child: CircularProgressIndicator())
                    : reportData == null
                    ? Center(
                        child: Text(
                          error ?? 'Нет данных',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(AppColors.uiBorder),
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
                              _NicknameCard(
                                nickname: selectedInvestor.nickname,
                                fullName: selectedInvestor.fullName,
                              ),
                              const SizedBox(height: 12),
                              _InvestorActions(
                                onEdit: _editInvestor,
                                onPayout: _createPayout,
                                onShare: _shareInvestor,
                                onAgreement: _showAgreement,
                                onExport: _shareReportPdf,
                              ),
                              const SizedBox(height: 16),
                              _AnalyticsGrid(metrics: _buildMetrics()),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: DefaultButton(
                                  text: 'Управлять кассой',
                                  isPrimary: false,
                                  onPressed: _openCashPositions,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'История операций',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _OperationChip(
                                      label: 'Выплаты',
                                      selected: operationsTab == 'payouts',
                                      onTap: () => setState(
                                        () => operationsTab = 'payouts',
                                      ),
                                    ),
                                    _OperationChip(
                                      label: 'Договоры',
                                      selected: operationsTab == 'credits',
                                      onTap: () => setState(
                                        () => operationsTab = 'credits',
                                      ),
                                    ),
                                    _OperationChip(
                                      label: 'Инвестиции',
                                      selected:
                                          operationsTab == 'contributions',
                                      onTap: () => setState(
                                        () => operationsTab = 'contributions',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildOperations(),
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
      if (payouts.isEmpty) return const _EmptyOperations(text: 'Выплат нет');
      return Column(
        children: payouts
            .map(
              (payout) => _OperationCard(
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
      if (credits.isEmpty) return const _EmptyOperations(text: 'Договоров нет');
      return Column(
        children: credits
            .map(
              (credit) => _OperationCard(
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
      return const _EmptyOperations(text: 'Инвестиций нет');
    }
    return Column(
      children: contributions
          .map(
            (contribution) => _OperationCard(
              title: '${formatNumber(contribution.amount)} ₽',
              subtitle: DateFormat('dd.MM.yyyy').format(contribution.date),
              status: contribution.confirmed
                  ? 'Подтверждено'
                  : 'Не подтверждено',
              trailing: PopupMenuButton<String>(
                onSelected: (action) =>
                    _contributionAction(contribution, action),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Редактировать'),
                  ),
                  if (!contribution.confirmed)
                    const PopupMenuItem(
                      value: 'confirm',
                      child: Text('Подтвердить'),
                    ),
                  const PopupMenuItem(
                    value: 'reject',
                    child: Text('Удалить', style: TextStyle(color: Colors.red)),
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

class _NicknameCard extends StatelessWidget {
  const _NicknameCard({required this.nickname, required this.fullName});

  final String nickname;
  final String fullName;

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
              color: Color(AppColors.uiBorder),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nickname,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 24 / 16,
              color: Color(AppColors.black),
            ),
          ),
          if (fullName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 14,
                color: Color(AppColors.uiBorder),
              ),
            ),
          ],
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
                  child: DashboardInfoMiniCard(
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
  });

  final VoidCallback onEdit;
  final VoidCallback onPayout;
  final VoidCallback onShare;
  final VoidCallback onAgreement;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionButton(
          icon: Icons.edit_outlined,
          label: 'Редактировать',
          onTap: onEdit,
        ),
        _ActionButton(
          icon: Icons.payments_outlined,
          label: 'Выплатить',
          onTap: onPayout,
        ),
        _ActionButton(icon: Icons.link, label: 'Поделиться', onTap: onShare),
        _ActionButton(
          icon: Icons.description_outlined,
          label: 'Договор',
          onTap: onAgreement,
        ),
        _ActionButton(
          icon: Icons.ios_share_outlined,
          label: 'Экспорт PDF',
          onTap: onExport,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: const Color(AppColors.primary)),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFD8DEE6)),
      onPressed: onTap,
    );
  }
}

class _OperationChip extends StatelessWidget {
  const _OperationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({
    required this.title,
    required this.subtitle,
    required this.status,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(AppColors.primary),
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

class _EmptyOperations extends StatelessWidget {
  const _EmptyOperations({required this.text});

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

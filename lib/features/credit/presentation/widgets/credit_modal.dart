import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/utils/phone_utils.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/clients/data/data_sources/clients/clients_remote_data_source.dart';
import 'package:waypay_mobile/features/clients/data/models/clients/client_model.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/add_note_dialog.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/create_payment_dialog.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/note.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay_mobile/features/note/data/models/note_model.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';
import 'package:waypay_mobile/features/payment/presentation/screen/schedule_screen.dart';
import 'package:waypay_mobile/features/sold_products/data/data_sources/sold_product_remote_data_source.dart';
import 'package:waypay_mobile/features/sold_products/data/models/sold_product_model.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditFullScreen extends StatefulWidget {
  final CreditModel credit;
  final bool isControl;

  const CreditFullScreen({
    super.key,
    required this.credit,
    required this.isControl,
  });

  @override
  State<CreditFullScreen> createState() => _CreditFullScreenState();
}

class _CreditFullScreenState extends State<CreditFullScreen> {
  List<NoteModel> _notes = [];
  List<ScheduleModel> _paymentPreview = [];
  final Set<int> _whatsAppLoading = <int>{};
  bool _isLoadingNotes = true;
  bool _isLoadingPayments = true;
  String? _paymentsError;
  ClientModel? _client;
  List<SoldProductModel> _soldProducts = [];
  List<CreditModel> _clientCredits = [];
  UserStorage userStorage = UserStorage();

  static const List<BoxShadow> _cardShadows = [
    BoxShadow(color: Color(0x14000809), offset: Offset(2, 2), blurRadius: 4),
    BoxShadow(color: Color(0x05000809), blurRadius: 6),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadPaymentPreview();
    _loadClient();
    _loadSoldProducts();
    _loadClientCredits();
  }

  Future<void> _loadClientCredits() async {
    try {
      final credits = await getIt<CreditRemoteDataSource>()
          .getCreditsByClientId(widget.credit.clientId);
      if (!mounted) return;
      setState(() {
        _clientCredits = credits
            .where((c) => c.id != widget.credit.id)
            .toList();
      });
    } catch (e) {
      debugPrint('Не удалось загрузить договоры клиента: $e');
    }
  }

  Future<void> _loadSoldProducts() async {
    try {
      final products = await getIt<SoldProductRemoteDataSource>()
          .fetchSoldProductsByCreditId(widget.credit.id);
      if (!mounted) return;
      setState(() => _soldProducts = products);
    } catch (e) {
      debugPrint('Не удалось загрузить товары: $e');
    }
  }

  Future<void> _loadClient() async {
    try {
      final client = await getIt<ClientRemoteDataSource>().getClientById(
        widget.credit.clientId,
      );
      if (!mounted) return;
      setState(() => _client = client);
    } catch (e) {
      debugPrint('Не удалось загрузить клиента: $e');
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        color: const Color(AppColors.background),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          bottom: false,
          child: Header(
            title: 'Договор №${widget.credit.id}',
            showBackButton: true,
            showNotifications: false,
            trailing: _buildTrailingActions(context),
          ),
        ),
      ),
    );
  }

  Widget? _buildTrailingActions(BuildContext context) {
    final shareButton = _buildShareButton(context);
    final deleteButton = _buildMenuButton(context);
    final actions = <Widget>[
      shareButton,
      if (deleteButton != null) deleteButton,
    ];
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  Widget _buildShareButton(BuildContext context) {
    return IconButton(
      icon: SvgPicture.asset(SvgIcons.share, width: 24, height: 24),
      tooltip: 'Поделиться',
      onPressed: () => _showShareSheet(context),
    );
  }

  Widget? _buildMenuButton(BuildContext context) {
    final canDelete = userStorage.hasViewContent([
      EmployeeRole.admin,
      EmployeeRole.director,
    ]);

    if (!canDelete) return null;

    return IconButton(
      icon: SvgPicture.asset(SvgIcons.delete),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    'Удаление договора №${widget.credit.id}',
                    textAlign: TextAlign.center,
                    style: AppStyle.manrope(
                      size: 20,
                      weight: FontWeight.w600,
                      color: const Color(AppColors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Это действие будет невозможно отменить,\nвы уверены что хотите удалить договор?',
                  textAlign: TextAlign.center,
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DefaultButton(
                        text: 'Отменить',
                        color: const Color(0xFFB7BFC8),
                        textColor: const Color(AppColors.black),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultButton(
                        text: 'Удалить',
                        color: const Color(AppColors.red),
                        textColor: Colors.white,
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        if (confirmed == true) {
          if (!context.mounted) return;
          debugPrint(
            '🟡 Подтверждено удаление договора ID: ${widget.credit.id}',
          );
          context.read<CreditBloc>().add(DeleteCreditEvent(widget.credit.id));
          Navigator.of(context).pop();
        }
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: _cardShadows,
    );
  }

  TextStyle get _labelTextStyle => AppStyle.manrope(
    size: 14,
    weight: FontWeight.w400,
    color: const Color(0xFF6B7280),
  );

  TextStyle get _valueTextStyle => AppStyle.manrope(
    size: 16,
    weight: FontWeight.w500,
    color: const Color(AppColors.black),
  );

  Widget _buildSummaryMetric(
    String label,
    String value, {
    bool highlight = false,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Expanded(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _labelTextStyle),
            const SizedBox(height: 4),
            Text(
              value,
              style: _valueTextStyle.copyWith(
                color: highlight
                    ? Color(AppColors.black)
                    : _valueTextStyle.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppColors.background),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCreditInfoSection(),
                    _buildGuarantorSection(),
                    _buildProductsSection(),
                    _buildClientCreditsSection(),
                    const SizedBox(height: 12),
                    _buildContactButtons(),
                    const SizedBox(height: 24),
                    _buildPaymentsSection(context),
                    const SizedBox(height: 16),
                    _buildAddPaymentButton(context),
                    const SizedBox(height: 24),
                    if (widget.isControl) _buildFinancialInfoSection(),
                    const SizedBox(height: 24),
                    _buildNotesSection(),
                  ],
                ),
              ),
            ),

            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ФИО клиента', style: _labelTextStyle),
          const SizedBox(height: 4),
          Text(widget.credit.clientFullName, style: _valueTextStyle),
          if (widget.credit.clientPhone.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Телефон', widget.credit.clientPhone),
          ],
          if ((_client?.registrationAddress ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Адрес регистрации', _client!.registrationAddress!),
          ],
          if ((_client?.actualAddress ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Фактический адрес', _client!.actualAddress!),
          ],
          const SizedBox(height: 16),
          _buildInfoRow(
            'Дата подписания',
            _formatDate(widget.credit.creditDate),
          ),
          if ((widget.credit.creditTypeName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Категория', widget.credit.creditTypeName!),
          ],
          if (widget.credit.investorNickname.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Инвестор', widget.credit.investorNickname),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryMetric(
                'Срок рассрочки',
                '${widget.credit.termMonths} мес.',
                padding: const EdgeInsets.only(right: 12),
              ),
              _buildSummaryMetric(
                'Сумма договора',
                _formatCurrency(widget.credit.totalAmount),
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryMetric(
                'Первоначальный взнос',
                _formatCurrency(widget.credit.firstPayment),
                padding: const EdgeInsets.only(right: 12),
                highlight: true,
              ),
              _buildSummaryMetric(
                'Начислено %',
                _formatCurrency(widget.credit.accured),
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryMetric(
                'Уплачено',
                _formatCurrency(widget.credit.payed),
                padding: const EdgeInsets.only(right: 12),
                highlight: true,
              ),
              _buildSummaryMetric(
                'Остаток',
                _formatCurrency(widget.credit.rest),
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryMetric(
                'Текущий долг',
                _formatCurrency(widget.credit.debt),
                highlight: true,
              ),
            ],
          ),
          if (widget.credit.debtDays != null &&
              widget.credit.debtDays! > 0) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Просрочка', '${widget.credit.debtDays} дн.'),
          ],
          if ((widget.credit.debtComment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Комментарий к долгу', widget.credit.debtComment!),
          ],
          if (widget.credit.terminated) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Статус', 'Договор расторгнут'),
          ],
        ],
      ),
    );
  }

  Widget _buildGuarantorSection() {
    final c = widget.credit;
    final hasGuarantor =
        (c.guarantorFullName ?? '').trim().isNotEmpty ||
        (c.guarantorPhone ?? '').trim().isNotEmpty ||
        (c.guarantorAddress ?? '').trim().isNotEmpty;
    if (!hasGuarantor) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Поручитель',
            style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if ((c.guarantorFullName ?? '').trim().isNotEmpty)
            _buildInfoRow('ФИО', c.guarantorFullName!),
          if ((c.guarantorPhone ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Телефон', c.guarantorPhone!),
          ],
          if ((c.guarantorAddress ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Адрес', c.guarantorAddress!),
          ],
          if ((c.guarantorBirthdate ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Дата рождения',
              _formatIsoDate(c.guarantorBirthdate!),
            ),
          ],
          if ((c.guarantorDoc ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Паспорт', c.guarantorDoc!),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_soldProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Товары',
            style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _soldProducts.length; i++) ...[
            if (i != 0)
              Divider(height: 20, thickness: 1, color: Colors.grey[200]),
            _buildProductRow(_soldProducts[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildProductRow(SoldProductModel product) {
    final surchargeMoney =
        product.surchargeAmount ??
        (product.surcharge != null
            ? product.price * product.surcharge! / 100
            : 0.0);
    final total = product.price + surchargeMoney;
    final surchargeLabel = product.surchargeAmount != null
        ? _formatCurrency(product.surchargeAmount!)
        : product.surcharge != null
        ? '${product.surcharge}%'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name, style: _valueTextStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildProductMetric('Стоимость', _formatCurrency(product.price)),
            _buildProductMetric('Надбавка', surchargeLabel),
            _buildProductMetric('Цена', _formatCurrency(total)),
          ],
        ),
      ],
    );
  }

  Widget _buildProductMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelTextStyle),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppStyle.manrope(size: 14, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCreditsSection() {
    if (_clientCredits.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Договоры клиента',
            style: AppStyle.manrope(size: 16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < _clientCredits.length; i++) ...[
            if (i != 0)
              Divider(height: 20, thickness: 1, color: Colors.grey[200]),
            _buildClientCreditRow(_clientCredits[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildClientCreditRow(CreditModel c) {
    // Эндпоинт Credit/list/{clientId} отдаёт только id/статус/дату — сумма и
    // остаток тут пустые, поэтому показываем лишь то, что реально есть.
    final statusLabel = (c.status != null && c.status!.trim().isNotEmpty)
        ? c.status!.trim()
        : (c.isActive ? 'активен' : 'архив');
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openClientCredit(c.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Договор № ${c.id}', style: _valueTextStyle),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(c.creditDate)} · $statusLabel',
                    style: _labelTextStyle,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  // Договор из списка неполный (только id/статус/дата), поэтому перед открытием
  // догружаем полную карточку по id.
  Future<void> _openClientCredit(int creditId) async {
    // showDialog показывает индикатор на root-навигаторе, поэтому и закрывать
    // его нужно им же (иначе ближайший навигатор ветки → бесконечная загрузка).
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    CreditModel? full;
    try {
      full = await getIt<CreditRemoteDataSource>().getCreditById(creditId);
    } catch (_) {
      full = null;
    }
    if (!mounted) return;
    rootNavigator.pop(); // закрываем индикатор загрузки
    if (full == null) {
      showAppMessage(
        context,
        'Не удалось загрузить договор',
        type: AppMessageType.error,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CreditFullScreen(credit: full!, isControl: widget.isControl),
      ),
    );
  }

  bool _isCallable(String value) => normalizeRussianPhone(value) != null;

  Future<void> _callPhone(BuildContext context, String value) async {
    final phone = formatRussianPhoneForCall(value);
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && context.mounted) {
      showAppMessage(
        context,
        'Не удалось открыть телефон',
        type: AppMessageType.error,
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String value) async {
    final phone = formatRussianPhoneForWhatsApp(value);
    if (phone == null) return;
    final uri = Uri.parse('https://wa.me/$phone');
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && context.mounted) {
      showAppMessage(
        context,
        'Не удалось открыть WhatsApp',
        type: AppMessageType.error,
      );
    }
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Поделиться в WhatsApp',
                  textAlign: TextAlign.center,
                  style: AppStyle.manrope(
                    size: 18,
                    weight: FontWeight.w600,
                    color: const Color(AppColors.black),
                  ),
                ),
                const SizedBox(height: 16),
                DefaultButton(
                  text: 'Данные по договору',
                  showIcon: true,
                  icon: Icons.description_outlined,
                  color: const Color(AppColors.primary),
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    _shareContractData();
                  },
                ),
                const SizedBox(height: 12),
                DefaultButton(
                  text: 'История платежей с остатком',
                  showIcon: true,
                  icon: Icons.event_note_outlined,
                  color: const Color(0xFF25D366),
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    _sharePaymentsHistory();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareContractData() async {
    final phone = formatRussianPhoneForWhatsApp(widget.credit.clientPhone);
    if (phone == null) {
      showAppMessage(
        context,
        'Не указан номер клиента',
        type: AppMessageType.error,
      );
      return;
    }
    final message = _buildContractMessage();
    await _launchWhatsApp(phone, message);
  }

  Future<void> _sharePaymentsHistory() async {
    final phone = formatRussianPhoneForWhatsApp(widget.credit.clientPhone);
    if (phone == null) {
      showAppMessage(
        context,
        'Не указан номер клиента',
        type: AppMessageType.error,
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String message;
    try {
      final schedule = await _loadFullSchedule();
      message = _buildPaymentsHistoryMessage(schedule);
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      showAppMessage(
        context,
        'Ошибка загрузки истории платежей: $e',
        type: AppMessageType.error,
      );
      return;
    }
    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    await _launchWhatsApp(phone, message);
  }

  Future<List<ScheduleModel>> _loadFullSchedule() async {
    final remote = getIt<ScheduleRemoteDataSources>();
    const pageSize = 100;
    final first = await remote.getScheduleByCredit(
      creditId: widget.credit.id,
      includePayed: true,
      page: 1,
      pageSize: pageSize,
    );
    final items = <ScheduleModel>[...first.items];
    for (int page = 2; page <= first.totalPages; page++) {
      final next = await remote.getScheduleByCredit(
        creditId: widget.credit.id,
        includePayed: true,
        page: page,
        pageSize: pageSize,
      );
      items.addAll(next.items);
    }
    return items;
  }

  String _buildPaymentsHistoryMessage(List<ScheduleModel> schedule) {
    final credit = widget.credit;
    final sorted = [...schedule]
      ..sort((a, b) {
        final da = DateTime.tryParse(a.paymentDate);
        final db = DateTime.tryParse(b.paymentDate);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    final buffer = StringBuffer()
      ..writeln('Здравствуйте, ${credit.clientFullName}!')
      ..writeln()
      ..writeln('История платежей по договору №${credit.id}')
      ..writeln();

    if (sorted.isEmpty) {
      buffer.write('Платежи ещё не внесены.');
      return buffer.toString();
    }

    for (final item in sorted) {
      final date = DateTime.tryParse(item.paymentDate);
      final dateLabel = date != null ? _formatDate(date) : item.paymentDate;
      final status = item.payed ? 'оплачен' : 'ожидается';
      buffer.writeln(
        '$dateLabel — ${_formatCurrency(item.paymentAmount)} '
        '($status), остаток: ${_formatCurrency(item.rest)}',
      );
    }

    buffer
      ..writeln()
      ..write('Итоговый остаток по договору: ${_formatCurrency(credit.rest)}');
    return buffer.toString();
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && mounted) {
      showAppMessage(
        context,
        'Не удалось открыть WhatsApp',
        type: AppMessageType.error,
      );
    }
  }

  String _buildContractMessage() {
    final credit = widget.credit;
    final buffer = StringBuffer()
      ..writeln('Здравствуйте, ${credit.clientFullName}!')
      ..writeln()
      ..writeln('Информация по договору №${credit.id}')
      ..writeln('Дата подписания: ${_formatDate(credit.creditDate)}')
      ..writeln('Срок рассрочки: ${credit.termMonths} мес.')
      ..writeln('Сумма договора: ${_formatCurrency(credit.totalAmount)}')
      ..writeln('Первоначальный взнос: ${_formatCurrency(credit.firstPayment)}')
      ..writeln('Начислено %: ${_formatCurrency(credit.accured)}')
      ..writeln('Уплачено: ${_formatCurrency(credit.payed)}')
      ..write('Остаток: ${_formatCurrency(credit.rest)}');
    return buffer.toString();
  }

  Widget _buildContactButtons() {
    final phone = widget.credit.clientPhone;
    final canCall = _isCallable(phone);

    return Row(
      children: [
        Expanded(
          child: DefaultButton(
            text: 'Звонок',
            showIcon: true,
            icon: Icons.phone,
            color: const Color(AppColors.primary),
            textColor: Colors.white,
            onPressed: canCall ? () => _callPhone(context, phone) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DefaultButton(
            text: 'WhatsApp',
            showIcon: true,
            icon: Icons.chat,
            color: const Color(0xFF25D366),
            textColor: Colors.white,
            onPressed: canCall ? () => _openWhatsApp(context, phone) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Финансовая информация',
          style: AppStyle.manrope(size: 18, weight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(
                'Начислено',
                _formatCurrency(widget.credit.accured),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Доход в %',
                '${widget.credit.incomePercents.toString()} %',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Доход в рублях',
                _formatCurrency(widget.credit.incomeRubles),
              ),
              if (widget.credit.totalClean != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Сумма без наценки',
                  _formatCurrency(widget.credit.totalClean!),
                ),
              ],
              if (widget.credit.defferedIncome != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Отложенный доход',
                  _formatCurrency(widget.credit.defferedIncome!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Заметки',
              style: AppStyle.manrope(
                size: 16,
                weight: FontWeight.w500,
                color: const Color(AppColors.black),
              ),
            ),
            TextButton(
              onPressed: () => showAddNoteDialog(context, widget.credit.id),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: Color(AppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Добавить заметку',
                    style: AppStyle.manrope(
                      size: 16,
                      weight: FontWeight.w400,
                      color: Color(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.add, size: 18, color: Color(AppColors.primary)),
                ],
              ),
            ),
          ],
        ),

        _isLoadingNotes
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
            ? const SizedBox.shrink()
            : ListView.separated(
                itemCount: _notes.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Note(
                    note: note,
                    onDelete: () {
                      setState(() {
                        _notes.removeAt(index);
                      });
                    },
                  );
                },
              ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelTextStyle),
          const SizedBox(height: 4),
          Text(value, style: _valueTextStyle),
        ],
      ),
    );
  }

  void _showCreatePaymentModal(BuildContext context, CreditModel credit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: CreatePaymentDialog(credit: credit),
        );
      },
    );
  }

  void showAddNoteDialog(BuildContext context, int creditId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddNoteDialog(
          creditId: creditId,
          onNoteAdded: () {
            _loadNotes();
          },
        );
      },
    );
  }

  Future<void> _loadPaymentPreview() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPayments = true;
      _paymentsError = null;
    });
    try {
      final remote = getIt<ScheduleRemoteDataSources>();
      final response = await remote.getScheduleByCredit(
        creditId: widget.credit.id,
        includePayed: true,
        page: 1,
        pageSize: 3,
      );
      final filtered = response.items.take(3).toList();
      if (!mounted) return;
      setState(() {
        _paymentPreview = filtered;
      });
    } catch (e, st) {
      debugPrint('Ошибка загрузки платежей: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _paymentsError = 'Ошибка загрузки платежей';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPayments = false;
        });
      }
    }
  }

  Future<void> _sendWhatsAppMessage(ScheduleModel schedule) async {
    final scheduleId = schedule.id;
    if (!mounted || _whatsAppLoading.contains(scheduleId)) return;

    final phone = formatRussianPhoneForWhatsApp(widget.credit.clientPhone);
    if (phone == null) {
      showAppMessage(
        context,
        'Не указан номер клиента',
        type: AppMessageType.error,
      );
      return;
    }

    setState(() => _whatsAppLoading.add(scheduleId));
    try {
      final remote = getIt<ScheduleRemoteDataSources>();
      final message = await remote.getFilledSender(scheduleId);
      final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw Exception('Не удалось открыть WhatsApp');
      }
      if (!schedule.notified) {
        await remote.putSchedule(scheduleId);
        await _loadPaymentPreview();
      }
    } catch (e) {
      if (!mounted) return;
      showAppMessage(context, 'Ошибка: $e', type: AppMessageType.error);
    } finally {
      if (mounted) {
        setState(() => _whatsAppLoading.remove(scheduleId));
      }
    }
  }

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );
  static final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'ru');
  static final DateFormat _shortDateFormat = DateFormat('dd.MM');

  String _formatCurrency(num amount) => _currencyFormat.format(amount);

  String _formatDate(DateTime date) => _dateFormat.format(date);

  String _formatIsoDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    return parsed != null ? _dateFormat.format(parsed) : raw;
  }

  Future<void> _loadNotes() async {
    try {
      final creditId = widget.credit.id;
      debugPrint('🔍 Загружаем заметки для creditId = $creditId');

      final noteDataSource = getIt<NoteRemoteDataSource>();
      final data = await noteDataSource.fetchNotesByCreditId(creditId);

      if (!mounted) return;
      setState(() {
        _notes = data;
        _isLoadingNotes = false;
      });
    } catch (e, stack) {
      debugPrint('❌ Ошибка при загрузке заметок: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;
      setState(() => _isLoadingNotes = false);

      showAppMessage(
        context,
        'Ошибка загрузки заметок: $e',
        type: AppMessageType.error,
      );
    }
  }

  Widget _buildPaymentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Платежи',
              style: AppStyle.manrope(size: 16, weight: FontWeight.w400),
            ),
            TextButton(
              onPressed: () => context.pushNamed(
                Routes.scheduleScreen.toName,
                extra: ScheduleScreenArgs(
                  creditId: widget.credit.id,
                  clientPhone: widget.credit.clientPhone,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: Color(AppColors.primary),
              ),
              child: Row(
                children: [
                  Text(
                    'Все платежи',
                    textAlign: TextAlign.center,
                    style: AppStyle.manrope(
                      size: 16,
                      weight: FontWeight.w400,
                      color: Color(AppColors.primary),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minHeight: 204),
          decoration: _cardDecoration(),
          child: _buildPaymentsContent(),
        ),
      ],
    );
  }

  Widget _buildPaymentsContent() {
    if (_isLoadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_paymentsError != null) {
      return _buildPaymentsPlaceholder(_paymentsError!);
    }
    if (_paymentPreview.isEmpty) {
      return _buildPaymentsPlaceholder('Платежи ещё не внесены');
    }
    return Column(
      children: [
        for (int i = 0; i < _paymentPreview.length; i++) ...[
          _buildPaymentTile(_paymentPreview[i]),
          if (i != _paymentPreview.length - 1)
            Divider(height: 20, thickness: 1, color: Colors.grey[200]),
        ],
      ],
    );
  }

  Widget _buildPaymentsPlaceholder(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.receipt_long, color: Colors.grey, size: 36),
        const SizedBox(height: 8),
        Text(
          message,
          style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentTile(ScheduleModel payment) {
    final date = DateTime.tryParse(payment.paymentDate);
    final isPaid = payment.payed;
    final isNotified = payment.notified;
    final isWhatsAppBusy = _whatsAppLoading.contains(payment.id);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPaymentDateBadge(date),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Договор № ${payment.creditId}',
                style: _valueTextStyle.copyWith(
                  color: const Color(AppColors.uiBorder),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(payment.paymentAmount),
                style: AppStyle.manrope(
                  size: 16,
                  weight: FontWeight.w500,
                  color: const Color(AppColors.black),
                ),
              ),
            ],
          ),
        ),
        if (isPaid)
          Row(
            children: [
              const Icon(Icons.check, color: Color(0xFF0FA958), size: 18),
              const SizedBox(width: 6),
              Text(
                'Оплачен',
                style: AppStyle.manrope(
                  size: 14,
                  weight: FontWeight.w500,
                  color: const Color(0xFF0FA958),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Text(
                isNotified ? 'Уведомлён' : 'Не уведомлён',
                style: AppStyle.manrope(
                  size: 14,
                  weight: FontWeight.w500,
                  color: isNotified
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF0FA958),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: isWhatsAppBusy
                    ? null
                    : () => _sendWhatsAppMessage(payment),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: isWhatsAppBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : isNotified
                      ? const Icon(
                          Icons.check,
                          size: 22,
                          color: Color(0xFF0FA958),
                        )
                      : Image.asset(Images.whatsappLogo, width: 24, height: 24),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentDateBadge(DateTime? date) {
    final label = date != null ? _shortDateFormat.format(date) : '--.--';
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFD1D5DB),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppStyle.manrope(
          size: 14,
          weight: FontWeight.w600,
          color: const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildAddPaymentButton(BuildContext context) {
    final allowed = userStorage.hasViewContent([
      EmployeeRole.admin,
      EmployeeRole.director,
      EmployeeRole.employee,
      EmployeeRole.superAdmin,
    ]);
    if (!allowed) return const SizedBox.shrink();

    return DefaultButton(
      text: 'Добавить платёж',
      onPressed: () {
        _showCreatePaymentModal(context, widget.credit);
      },
      isPrimary: true,
    );
  }
}

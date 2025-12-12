import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/add_note_dialog.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';

import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/create_payment_dialog.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/note.dart';
import 'package:waypay_mobile/features/note/data/data_sources/note_remote_data_source.dart';
import 'package:waypay_mobile/features/note/data/models/note_model.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';
import 'package:waypay_mobile/features/sold_products/data/data_sources/sold_product_remote_data_source.dart';
import 'package:waypay_mobile/features/sold_products/data/models/sold_product_model.dart';
import 'package:waypay_mobile/routes/routes.dart';

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
  List<SoldProductModel> _soldProducts = [];
  List<ScheduleModel> _paymentPreview = [];
  bool _isLoadingNotes = true;
  bool _isLoadingProducts = true;
  bool _isLoadingPayments = true;
  String? _paymentsError;
  UserStorage userStorage = UserStorage();

  static const List<BoxShadow> _cardShadows = [
    BoxShadow(color: Color(0x14000809), offset: Offset(2, 2), blurRadius: 4),
    BoxShadow(color: Color(0x05000809), blurRadius: 6),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadSoldProducts();
    _loadPaymentPreview();
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
            trailing: _buildMenuButton(context),
          ),
        ),
      ),
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
    final userStorage = UserStorage();
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

  double _calculateTotalAmount() {
    return _soldProducts.fold(0.0, (sum, product) => sum + product.totalAmount);
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
          const SizedBox(height: 16),
          _buildInfoRow(
            'Дата подписания',
            _formatDate(widget.credit.creditDate),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryMetric(
                'Срок рассрочки',
                '${widget.credit.termMonths} мес.',
                padding: const EdgeInsets.only(right: 12),
              ),
              _buildSummaryMetric(
                'Общий долг',
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
        ],
      ),
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
                color: Colors.black.withOpacity(0.05),
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
      if (!mounted) return;
      setState(() {
        _isLoadingPayments = false;
      });
    }
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'ru').format(date);
  }

  Future<void> _loadNotes() async {
    try {
      final creditId = widget.credit.id;
      debugPrint('🔍 Загружаем заметки для creditId = $creditId');

      final noteDataSource = getIt<NoteRemoteDataSource>();
      final data = await noteDataSource.fetchNotesByCreditId(creditId);

      setState(() {
        _notes = data;
        _isLoadingNotes = false;
      });
    } catch (e, stack) {
      debugPrint('❌ Ошибка при загрузке заметок: $e');
      debugPrintStack(stackTrace: stack);

      setState(() => _isLoadingNotes = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки заметок: $e')));
      }
    }
  }

  Future<void> _loadSoldProducts() async {
    try {
      final creditId = widget.credit.id;
      debugPrint('🛍️ Загружаем проданные товары для creditId = $creditId');

      final productDataSource = getIt<SoldProductRemoteDataSource>();
      final data = await productDataSource.fetchSoldProductsByCreditId(
        creditId,
      );

      setState(() {
        _soldProducts = data;
        _isLoadingProducts = false;
      });
    } catch (e, stack) {
      debugPrint('❌ Ошибка при загрузке проданных товаров: $e');
      debugPrintStack(stackTrace: stack);

      setState(() => _isLoadingProducts = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки товаров: $e')));
      }
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
                extra: widget.credit.id,
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
                  color: const Color(AppColors.darkGrey),
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
        Row(
          children: [
            Icon(
              isPaid ? Icons.check : Icons.schedule,
              color: isPaid ? const Color(0xFF0FA958) : const Color(0xFF6B7280),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isPaid ? 'Оплачен' : 'Запланирован',
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w500,
                color: isPaid ? const Color(0xFF0FA958) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentDateBadge(DateTime? date) {
    final label = date != null ? DateFormat('dd.MM').format(date) : '--.--';
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

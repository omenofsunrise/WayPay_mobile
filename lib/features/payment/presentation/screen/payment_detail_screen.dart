import 'package:flutter/material.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/create_payment_dialog.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';

class PaymentDetailScreen extends StatefulWidget {
  const PaymentDetailScreen({super.key, this.schedule, this.payment})
    : assert(schedule != null || payment != null);

  final ScheduleModel? schedule;
  final PaymentItemModel? payment;

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final _creditSource = getIt<CreditRemoteDataSource>();
  final _paymentSource = getIt<PaymentRemoteDataSources>();
  CreditModel? _credit;
  int? _resolvedCreditId;
  bool _isLoading = true;
  late bool _paymentCreated;
  String? _error;

  ScheduleModel? get _schedule => widget.schedule;
  PaymentItemModel? get _payment => widget.payment;
  String get _clientName =>
      _schedule?.clientName ?? _payment?.clientFullName ?? '';
  int get _creditId =>
      _resolvedCreditId ?? _schedule?.creditId ?? _payment?.creditId ?? 0;
  double get _paymentAmount =>
      _schedule?.paymentAmount ?? _payment?.paymentAmount ?? 0;
  String get _paymentDateRaw =>
      _schedule?.paymentDate ?? _payment?.paymentDate ?? '';
  // Подтверждение платежей выключено — внесённый платёж уже оплачен,
  // ждать подтверждения ему не нужно.
  bool get _isPaid =>
      _payment?.accepted == true ||
      (_payment != null && !UserStorage().paymentAcceptance) ||
      _schedule?.payed == true ||
      _paymentCreated;
  bool get _canCreatePayment =>
      _schedule != null && !_isPaid && _credit != null;

  @override
  void initState() {
    super.initState();
    _paymentCreated = _payment?.accepted ?? false;
    _loadCredit();
  }

  Future<void> _loadCredit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final creditId = await _resolveCreditId();
      if (creditId == null || creditId <= 0) {
        if (!mounted) return;
        setState(() {
          _error = 'Не удалось определить договор для этого платежа';
          _isLoading = false;
        });
        return;
      }
      final credit = await _creditSource.getCreditById(creditId);
      if (!mounted) return;
      setState(() {
        _resolvedCreditId = creditId;
        _credit = credit;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<int?> _resolveCreditId() async {
    final scheduleCreditId = _schedule?.creditId;
    if (scheduleCreditId != null && scheduleCreditId > 0) {
      return scheduleCreditId;
    }

    final paymentCreditId = _payment?.creditId;
    if (paymentCreditId != null && paymentCreditId > 0) {
      return paymentCreditId;
    }

    final paymentId = _payment?.id;
    if (paymentId == null || paymentId <= 0) {
      return null;
    }

    final freshPayment = await _paymentSource.getPaymentById(paymentId);
    if (freshPayment.creditId > 0) {
      return freshPayment.creditId;
    }
    return null;
  }

  String _formatCurrency(num? value) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    if (value == null) return '—';
    return formatter.format(value);
  }

  String _formatIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  DateTime? _parsePaymentDate() {
    if (_paymentDateRaw.isEmpty) return null;
    try {
      return DateTime.parse(_paymentDateRaw);
    } catch (_) {
      return null;
    }
  }

  void _showCreatePaymentModal() {
    final credit = _credit;
    if (!_canCreatePayment || credit == null) return;

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
          child: CreatePaymentDialog(
            credit: credit,
            initialDate: _parsePaymentDate(),
            initialAmount: _paymentAmount,
            onPaymentCreated: () {
              if (!mounted) return;
              setState(() => _paymentCreated = true);
              _loadCredit();
            },
          ),
        );
      },
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
                title: 'Детали платежа',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildContent()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          DefaultButton(
            text: 'Повторить',
            color: const Color(AppColors.primary),
            textColor: Colors.white,
            onPressed: _loadCredit,
          ),
        ],
      );
    }
    final credit = _credit;
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ФИО клиента',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(AppColors.uiBorder),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _clientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(isPaid: _isPaid),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(label: 'Договор', value: '№ $_creditId'),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Сумма договора',
              value: _formatCurrency(credit?.totalAmount),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Дата платежа',
              value: _formatIsoDate(_paymentDateRaw),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Сумма платежа',
              value: _formatCurrency(_paymentAmount),
            ),
            if (_canCreatePayment) ...[
              const SizedBox(height: 20),
              DefaultButton(
                text: 'Добавить платёж',
                isPrimary: true,
                onPressed: _showCreatePaymentModal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(AppColors.uiBorder),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(AppColors.black),
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final text = isPaid ? 'Оплачен' : 'Не оплачен';
    final background = isPaid
        ? const Color(AppColors.primaryLight)
        : const Color(0xFFE2E4EA);
    final color = isPaid
        ? const Color(AppColors.primary)
        : const Color(AppColors.black);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
          height: 1.3,
        ),
      ),
    );
  }
}

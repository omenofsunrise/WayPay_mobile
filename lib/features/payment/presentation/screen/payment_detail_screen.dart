import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/features/credit/data/data_source/credit_remote_data_source.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/schedule/schedule_remote_data_sources.dart';
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
  final _scheduleSource = getIt<ScheduleRemoteDataSources>();
  CreditModel? _credit;
  bool _isLoading = true;
  late bool _isNotified;
  bool _notifyLoading = false;
  String? _error;
  final NumberFormat _plainCurrencyFormatter = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '',
    decimalDigits: 0,
  );

  ScheduleModel? get _schedule => widget.schedule;
  PaymentItemModel? get _payment => widget.payment;
  String get _clientName =>
      _schedule?.clientName ?? _payment?.clientFullName ?? '';
  int get _creditId => _schedule?.creditId ?? _payment?.creditId ?? 0;
  double get _paymentAmount =>
      _schedule?.paymentAmount ?? _payment?.paymentAmount ?? 0;
  String get _paymentDateRaw =>
      _schedule?.paymentDate ?? _payment?.paymentDate ?? '';
  String? get _clientPhone => _schedule?.clientPhone ?? _credit?.clientPhone;
  bool get _isPaid => _payment?.accepted == true || _isNotified;

  @override
  void initState() {
    super.initState();
    _isNotified = _schedule?.notified ?? _payment?.accepted ?? false;
    _loadCredit();
  }

  Future<void> _loadCredit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final credit = await _creditSource.getCreditById(_creditId);
      if (!mounted) return;
      setState(() {
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

  Future<void> _contactClient() async {
    final phoneRaw = _clientPhone;
    if (phoneRaw == null || phoneRaw.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не указан номер клиента')));
      return;
    }
    if (_notifyLoading) return;
    setState(() => _notifyLoading = true);
    try {
      if (_schedule != null && !_isNotified) {
        await _scheduleSource.putSchedule(_schedule!.id);
        _isNotified = true;
      }
      final phone = _preparePhone(phoneRaw);
      if (phone == null) {
        throw Exception('Неверный номер клиента');
      }
      await _openWhatsApp(phone, _buildWhatsappMessage());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) {
        setState(() => _notifyLoading = false);
      }
    }
  }

  String? _preparePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    } else if (!digits.startsWith('7')) {
      digits = '7$digits';
    }
    return digits;
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

  String _formatPlainCurrency(num? value) {
    if (value == null) return '—';
    return _plainCurrencyFormatter.format(value).trim();
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

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  int _overdueDays() {
    final due = DateTime.tryParse(_paymentDateRaw);
    if (due == null) return 0;
    final diff = DateTime.now().difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  String _paymentDayDescription() {
    final due = DateTime.tryParse(_paymentDateRaw);
    if (due == null) return '—';
    final day = due.day;
    return '$day число каждого следующего месяца.';
  }

  String _buildWhatsappMessage() {
    final companyName = (_credit?.employeeName?.trim().isNotEmpty ?? false)
        ? _credit!.employeeName
        : 'WayPay';
    final amount = _formatPlainCurrency(_paymentAmount);
    final date = _formatIsoDate(_paymentDateRaw);
    final rest = _formatPlainCurrency(_credit?.rest);
    final purchaseDate = _formatDate(_credit?.creditDate);
    final paymentDay = _paymentDayDescription();
    final overdue = _overdueDays();
    const supportPhone = '+7 928 ХХХ-ХХ-ХХ';

    return 'Клиент уведомлён в WhatsApp компании $companyName в размере '
        '$amount, $date.\n\n'
        'РЕКВИЗИТЫ для перевода:\n\n'
        'Остаток: $rest рублей.\n'
        'Дата покупки: $purchaseDate.\n'
        'Дата оплаты: $paymentDay\n'
        'ПРОСРОЧКА (дни): $overdue.\n\n'
        'В случае просрочки без причины, мы вынуждены будем принять меры!🚫\n'
        'Не портите вашу историю рассрочки!\n\n'
        'Телефон поддержки:\n$supportPhone';
  }

  Future<void> _openWhatsApp(String phone, String message) async {
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть WhatsApp')),
      );
    }
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
                showNotifications: true,
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
                          color: Color(AppColors.darkGrey),
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
              color: Color(AppColors.darkGrey),
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

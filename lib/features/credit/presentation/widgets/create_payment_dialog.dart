import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/form_modal/label_text_field.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_calendar.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';
import 'package:waypay_mobile/core/widgets/CustomRadioButton.dart';
import 'package:waypay_mobile/features/bank_card/data/data_sources/bank_card_remote_data_source.dart';
import 'package:waypay_mobile/features/bank_card/data/models/bank_card_model.dart';
import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay_mobile/features/payment/data/data_sources/expected/payment_remote_data_sources.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';

class CreatePaymentDialog extends StatefulWidget {
  final CreditModel credit;

  const CreatePaymentDialog({super.key, required this.credit});

  @override
  State<CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<CreatePaymentDialog> {
  final _contractController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _currentDebtController = TextEditingController();
  final _restController = TextEditingController();
  final _bankCardController = TextEditingController();
  DateTime? _selectedDate;
  PaymentType? _selectedType;
  int? _selectedBankCardId;
  List<BankCardModel> _bankCards = [];
  bool _isLoadingCards = false;
  String? _cardsError;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contractController.text = widget.credit.id.toString();
    _currentDebtController.text = _formatCurrency(widget.credit.debt);
    _restController.text = _formatCurrency(widget.credit.rest);
    _selectedType = PaymentType.cash;
    _amountController.addListener(_onFieldChanged);
    _dateController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _contractController.dispose();
    _dateController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _amountController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _currentDebtController.dispose();
    _restController.dispose();
    _bankCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _selectedType ??= PaymentType.cash;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Новый платёж',
                        style: AppStyle.manrope(
                          size: 20,
                          weight: FontWeight.w600,
                          color: const Color(AppColors.black),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Сведения о договоре',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildModalField(
                  controller: _contractController,
                  label: '№ договора',
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Сведения о платеже',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildDatePickerField(),
                const SizedBox(height: 12),
                _buildModalField(
                  controller: _amountController,
                  label: 'Сумма платежа',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(),
                    LengthLimitingTextInputFormatter(15),
                  ],
                ),
                const SizedBox(height: 12),
                _buildModalField(
                  controller: _currentDebtController,
                  label: 'Текущая задолженность',
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                _buildModalField(
                  controller: _restController,
                  label: 'Остаток долга',
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Способ оплаты',
                  style: AppStyle.manrope(size: 16, weight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildPaymentTypeSelector(),
                const SizedBox(height: 12),
                _buildBankCardSelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DefaultButton(
                        text: 'Отменить',
                        color: const Color(0xFFB7BFC8),
                        textColor: const Color(AppColors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DefaultButton(
                        text: 'Создать платёж',
                        isPrimary: true,
                        onPressed: _canSubmit ? _submitPayment : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Row(
      children: [
        CustomRadioButton(
          value: true,
          groupValue: _selectedType == PaymentType.cash,
          onChanged: (_) => _onPaymentTypeChanged(PaymentType.cash),
          label: 'Наличные',
        ),
        const SizedBox(width: 16),
        CustomRadioButton(
          value: true,
          groupValue: _selectedType == PaymentType.card,
          onChanged: (_) => _onPaymentTypeChanged(PaymentType.card),
          label: 'Карта',
        ),
      ],
    );
  }

  Future<void> _submitPayment() async {
    if (_isSubmitting) return;
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(text);

    if (_selectedDate == null || amount == null || _selectedType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = getIt<PaymentRemoteDataSources>();
      await api.createPayment(
        creditId: widget.credit.id,
        paymentAmount: amount,
        datePayment: _selectedDate!,
        type: _selectedType!,
        bankCardId: _selectedType == PaymentType.card ? _selectedBankCardId : null,
      );

      if (context.mounted) {
        final creditBloc = context.read<CreditBloc>();
        creditBloc.add(
          LoadCreditsEvent(refresh: true, query: creditBloc.lastQuery),
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Платёж успешно создан')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при создании платежа: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    await showDialog(
      context: context,
      builder: (ctx) => CustomCalendar(
        initialDate: _selectedDate ?? DateTime.now(),
        prefix: 'Дата:',
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
            _dateController.text = DateFormat('dd.MM.yyyy').format(date);
          });
        },
      ),
    );
  }

  bool get _canSubmit {
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(text);
    final bankCardValid = _selectedType != PaymentType.card || _selectedBankCardId != null;
    return !_isSubmitting &&
        _selectedDate != null &&
        amount != null &&
        _selectedType != null &&
        bankCardValid;
  }

  void _onFieldChanged() {
    setState(() {});
  }

  Widget _buildModalField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return ModalTextField(
      controller: controller,
      label: label,
      hintText: hintText ?? label,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildDatePickerField() {
    return ModalTextField(
      controller: _dateController,
      label: 'Дата платежа',
      hintText: 'Выберите дату',
      readOnly: true,
      onTap: _pickDate,
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SvgPicture.asset(
          SvgIcons.calendar,
          width: 20,
          height: 20,
          color: const Color(0xFF6B717C),
        ),
      ),
      suffixIconConstraints: const BoxConstraints(
        minHeight: 24,
        minWidth: 32,
        maxWidth: 60,
      ),
    );
  }

  Future<void> _loadBankCards() async {
    if (_isLoadingCards) return;
    setState(() {
      _isLoadingCards = true;
      _cardsError = null;
    });
    try {
      final dataSource = getIt<BankCardRemoteDataSource>();
      final result = await dataSource.getBankCards(page: 1, pageSize: 50);
      if (!mounted) return;
      setState(() {
        _bankCards = result.items;
        if (_bankCards.isNotEmpty && _selectedBankCardId == null) {
          _selectedBankCardId = _bankCards.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cardsError = 'Не удалось загрузить карты: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingCards = false;
      });
    }
  }

  void _onPaymentTypeChanged(PaymentType? value) {
    setState(() {
      _selectedType = value;
      if (value != PaymentType.card) {
        _selectedBankCardId = null;
        _bankCardController.clear();
      } else if (_bankCards.isEmpty && !_isLoadingCards) {
        _loadBankCards();
      }
    });
  }

  Widget _buildBankCardSelector() {
    if (_selectedType != PaymentType.card) return const SizedBox.shrink();

    if (_isLoadingCards) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cardsError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _cardsError!,
          style: AppStyle.manrope(
            size: 14,
            weight: FontWeight.w500,
            color: const Color(AppColors.red),
          ),
        ),
      );
    }

    if (_bankCards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Нет сохранённых карт. Добавьте карту в веб-версии или через поддержку.',
          style: AppStyle.manrope(
            size: 14,
            weight: FontWeight.w500,
            color: const Color(0xFF6B717C),
          ),
        ),
      );
    }

    final selectedCard = _bankCards.firstWhere(
      (card) => card.id == _selectedBankCardId,
      orElse: () => _bankCards.first,
    );

    final displayValue = _selectedBankCardId != null
        ? _formatCard(selectedCard)
        : 'Выберите карту';
    _bankCardController.text = displayValue;

    return ModalTextField(
      controller: _bankCardController,
      label: 'Банковская карта',
      readOnly: true,
      onTap: () => _showCardPicker(),
      suffixIcon: const Icon(Icons.keyboard_arrow_down),
    );
  }

  void _showCardPicker() {
    showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _bankCards.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final card = _bankCards[index];
              return ListTile(
                title: Text(
                  _formatCard(card),
                  style: AppStyle.manrope(
                    size: 16,
                    weight: FontWeight.w500,
                    color: const Color(AppColors.black),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(card.id),
              );
            },
          ),
        );
      },
    ).then((selectedId) {
      if (selectedId == null) return;
      setState(() {
        _selectedBankCardId = selectedId;
      });
    });
  }

  String _formatCard(BankCardModel card) {
    final details = card.details?.trim();
    final phone = card.phone?.trim();
    if (details != null && details.isNotEmpty && phone != null && phone.isNotEmpty) {
      return '$details • $phone';
    }
    if (details != null && details.isNotEmpty) return details;
    if (phone != null && phone.isNotEmpty) return phone;
    return 'Карта #${card.id}';
  }

  String _formatCurrency(num value) {
    final format = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return format.format(value);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';

import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/payment/presentation/models/payment_history_filters.dart';

class PaymentHistoryFiltersSheet extends StatelessWidget {
  const PaymentHistoryFiltersSheet({super.key, this.initialFilters});

  final PaymentHistoryFilters? initialFilters;

  @override
  Widget build(BuildContext context) {
    return FilterSheet(
      child: _PaymentHistoryFiltersForm(initialFilters: initialFilters),
    );
  }
}

class _PaymentHistoryFiltersForm extends StatefulWidget {
  const _PaymentHistoryFiltersForm({this.initialFilters});

  final PaymentHistoryFilters? initialFilters;

  @override
  State<_PaymentHistoryFiltersForm> createState() =>
      _PaymentHistoryFiltersFormState();
}

class _PaymentHistoryFiltersFormState
    extends State<_PaymentHistoryFiltersForm> {
  final _clientController = TextEditingController();
  final _investorController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool? _confirmed;

  final _dateFormat = DateFormat('dd.MM.yyyy');

  List<TextEditingController> get _controllers => [
    _clientController,
    _investorController,
    _dateFromController,
    _dateToController,
  ];

  @override
  void initState() {
    super.initState();
    _applyInitialValues();
    for (final controller in _controllers) {
      controller.addListener(_onFieldsChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_onFieldsChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _applyInitialValues() {
    final filters = widget.initialFilters;
    if (filters == null) return;
    _clientController.text = filters.clientName ?? '';
    _investorController.text = filters.investor ?? '';
    _dateFrom = filters.dateFrom;
    _dateTo = filters.dateTo;
    _dateFromController.text = _formatDate(_dateFrom);
    _dateToController.text = _formatDate(_dateTo);
    _confirmed = filters.confirmed;
  }

  void _onFieldsChanged() => setState(() {});

  bool get _hasAnyValue =>
      _controllers.any((c) => c.text.trim().isNotEmpty) ||
      _dateFrom != null ||
      _dateTo != null ||
      _confirmed != null;

  Future<void> _pickDate({required bool isFrom}) async {
    final initialDate = isFrom
        ? _dateFrom ?? DateTime.now()
        : _dateTo ?? _dateFrom ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
          _dateFromController.text = _formatDate(picked);
        } else {
          _dateTo = picked;
          _dateToController.text = _formatDate(picked);
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  PaymentHistoryFilters _buildFilters() {
    return PaymentHistoryFilters(
      clientName: _clientController.text.trim().isEmpty
          ? null
          : _clientController.text.trim(),
      investor: _investorController.text.trim().isEmpty
          ? null
          : _investorController.text.trim(),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      confirmed: _confirmed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Статус платежа',
          style: TextStyle(fontSize: 14, color: Color(AppColors.uiBorder)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _buildStatusChip('Просрочен', false),
            _buildStatusChip('Оплачен', true),
          ],
        ),
        const SizedBox(height: 24),
        ModalTextField(
          controller: _clientController,
          label: 'ФИО клиента',
          hintText: 'Введите ФИО',
        ),
        const SizedBox(height: 12),
        ModalTextField(
          controller: _investorController,
          label: 'Инвестор',
          hintText: 'Введите имя',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ModalTextField(
                controller: _dateFromController,
                label: 'Дата от',
                hintText: 'Выберите дату',
                readOnly: true,
                onTap: () => _pickDate(isFrom: true),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SvgPicture.asset(
                    SvgIcons.calendar,
                    width: 20,
                    height: 20,
                    color: const Color(0xFF6B717C),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModalTextField(
                controller: _dateToController,
                label: 'Дата до',
                hintText: 'Выберите дату',
                readOnly: true,
                onTap: () => _pickDate(isFrom: false),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SvgPicture.asset(
                    SvgIcons.calendar,
                    width: 20,
                    height: 20,
                    color: const Color(0xFF6B717C),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: DefaultButton(
                text: 'Отменить',
                color: const Color(0xFFB8BEC8),
                textColor: const Color(AppColors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultButton(
                text: 'Применить',
                color: _hasAnyValue
                    ? const Color(AppColors.primary)
                    : const Color(0xFFA8DADB),
                textColor: Colors.white,
                onPressed: () {
                  final result = _hasAnyValue
                      ? _buildFilters()
                      : const PaymentHistoryFilters();
                  Navigator.of(context).pop(result);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool value) {
    final bool selected = _confirmed == value;
    final fillColor = selected ? const Color(AppColors.primary) : Colors.white;
    final borderColor = selected
        ? const Color(AppColors.primary)
        : const Color(0xFFD9DDE5);

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(AppColors.primary),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(AppColors.black),
        fontWeight: FontWeight.w500,
      ),
      onSelected: (_) {
        setState(() {
          _confirmed = selected ? null : value;
        });
      },
    );
  }
}

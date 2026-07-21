import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';

import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/features/payment/presentation/models/schedule_filters.dart';

class ScheduleFiltersSheet extends StatelessWidget {
  const ScheduleFiltersSheet({super.key, this.initialFilters});

  final ScheduleFilters? initialFilters;

  @override
  Widget build(BuildContext context) {
    return FilterSheet(
      child: _ScheduleFiltersForm(initialFilters: initialFilters),
    );
  }
}

class _ScheduleFiltersForm extends StatefulWidget {
  const _ScheduleFiltersForm({this.initialFilters});

  final ScheduleFilters? initialFilters;

  @override
  State<_ScheduleFiltersForm> createState() => _ScheduleFiltersFormState();
}

class _ScheduleFiltersFormState extends State<_ScheduleFiltersForm> {
  final _contractController = TextEditingController();
  final _investorController = TextEditingController();
  final _clientController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  DateTime? _dateFrom;
  DateTime? _dateTo;

  final _dateFormat = DateFormat('dd.MM.yyyy');

  List<TextEditingController> get _controllers => [
    _contractController,
    _investorController,
    _clientController,
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

  void _onFieldsChanged() => setState(() {});

  bool get _hasAnyValue => _controllers.any((c) => c.text.trim().isNotEmpty);

  void _applyInitialValues() {
    final filters = widget.initialFilters;
    if (filters == null) return;
    if (filters.contractNumber != null) {
      _contractController.text = filters.contractNumber.toString();
    }
    _investorController.text = filters.investor ?? '';
    _clientController.text = filters.clientFullName ?? '';
    _dateFrom = filters.dateFrom;
    _dateTo = filters.dateTo;
    _dateFromController.text = _formatDate(_dateFrom);
    _dateToController.text = _formatDate(_dateTo);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initialDate = isFrom
        ? _dateFrom ?? DateTime.now()
        : _dateTo ?? _dateFrom ?? DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

  ScheduleFilters _buildFilters() {
    return ScheduleFilters(
      contractNumber: _parseContract(_contractController.text),
      investor: _investorController.text.trim().isEmpty
          ? null
          : _investorController.text.trim(),
      clientFullName: _clientController.text.trim().isEmpty
          ? null
          : _clientController.text.trim(),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  int? _parseContract(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return ModalTextField(
      controller: controller,
      label: label,
      hintText: 'Выберите дату',
      readOnly: true,
      onTap: onTap,
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SvgPicture.asset(
          SvgIcons.calendar,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            const Color(0xFF6B717C),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModalTextField(
          controller: _contractController,
          label: '№ договора',
          hintText: 'Введите номер',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                controller: _dateFromController,
                label: 'Дата от',
                onTap: () => _pickDate(isFrom: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                controller: _dateToController,
                label: 'Дата до',
                onTap: () => _pickDate(isFrom: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ModalTextField(
          controller: _investorController,
          label: 'Инвестор',
          hintText: 'Введите имя',
        ),
        const SizedBox(height: 12),
        ModalTextField(
          controller: _clientController,
          label: 'ФИО клиента',
          hintText: 'Введите ФИО',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: DefaultButton(
                text: 'Сбросить',
                color: const Color(0xFFB8BEC8),
                textColor: const Color(AppColors.black),
                onPressed: () {
                  for (final controller in _controllers) {
                    controller.clear();
                  }
                  setState(() {
                    _dateFrom = null;
                    _dateTo = null;
                  });
                },
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
                  if (!_hasAnyValue) return;
                  Navigator.of(context).pop(_buildFilters());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

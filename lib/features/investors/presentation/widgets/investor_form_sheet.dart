import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';

Future<bool?> showInvestorFormSheet(
  BuildContext context, {
  InvestorsModel? investor,
  int? poolId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _InvestorFormSheet(investor: investor, poolId: poolId),
  );
}

class _InvestorFormSheet extends StatefulWidget {
  const _InvestorFormSheet({this.investor, this.poolId});

  final InvestorsModel? investor;
  final int? poolId;

  @override
  State<_InvestorFormSheet> createState() => _InvestorFormSheetState();
}

class _InvestorFormSheetState extends State<_InvestorFormSheet> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _pieController;
  late final TextEditingController _investmentController;
  late DateTime _activeUntil;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.investor != null;

  @override
  void initState() {
    super.initState();
    final investor = widget.investor;
    _nicknameController = TextEditingController(text: investor?.nickname ?? '');
    _fullNameController = TextEditingController(text: investor?.fullName ?? '');
    _phoneController = TextEditingController(text: investor?.phoneNumber ?? '');
    _pieController = TextEditingController(
      text: investor?.investorPie.toString() ?? '50',
    );
    _investmentController = TextEditingController(text: '0');
    _activeUntil =
        investor?.contractEndDate ??
        DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _pieController.dispose();
    _investmentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _activeUntil,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('ru', 'RU'),
    );
    if (selected != null && mounted) setState(() => _activeUntil = selected);
  }

  double? _parseAmount(String value) =>
      double.tryParse(value.trim().replaceAll(' ', '').replaceAll(',', '.'));

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final nickname = _nicknameController.text.trim();
    final pie = int.tryParse(_pieController.text.trim());
    final investment = _parseAmount(_investmentController.text);

    if (fullName.isEmpty || nickname.isEmpty) {
      setState(() => _error = 'Заполните ФИО и никнейм');
      return;
    }
    if (pie == null || pie < 0 || pie > 100) {
      setState(() => _error = 'Доля инвестора должна быть от 0 до 100');
      return;
    }
    if (!_isEditing && (investment == null || investment < 0)) {
      setState(() => _error = 'Введите корректную сумму инвестиции');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final source = getIt<InvestorsRemoteDataSource>();
      if (_isEditing) {
        await source.updateInvestor(
          id: widget.investor!.id,
          nickname: nickname,
          fullName: fullName,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          investorPie: pie,
          activeUntil: _activeUntil,
        );
      } else {
        await source.createInvestor(
          nickname: nickname,
          fullName: fullName,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          investorPie: pie,
          investmentAmount: investment!,
          activeUntil: _activeUntil,
          poolId: widget.poolId,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Ошибка: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Редактировать инвестора' : 'Новый инвестор',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FormField(controller: _nicknameController, label: 'Никнейм'),
              _FormField(controller: _fullNameController, label: 'ФИО'),
              _FormField(
                controller: _phoneController,
                label: 'Телефон',
                keyboardType: TextInputType.phone,
              ),
              _FormField(
                controller: _pieController,
                label: 'Доля инвестора, %',
                keyboardType: TextInputType.number,
              ),
              if (!_isEditing)
                _FormField(
                  controller: _investmentController,
                  label: 'Начальная инвестиция, ₽',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              const Text(
                'Дата окончания договора',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(AppColors.uiBorder),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saving ? null : _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD8DEE6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(DateFormat('dd.MM.yyyy').format(_activeUntil)),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: DefaultButton(
                  text: _saving ? 'Сохранение…' : 'Сохранить',
                  isPrimary: true,
                  onPressed: _saving ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

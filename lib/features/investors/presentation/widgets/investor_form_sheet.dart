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
  return showWayPayBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
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
  late final TextEditingController _dateController;
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
    _dateController = TextEditingController(
      text: DateFormat('dd.MM.yyyy').format(_activeUntil),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _pieController.dispose();
    _investmentController.dispose();
    _dateController.dispose();
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
    if (selected != null && mounted) {
      setState(() {
        _activeUntil = selected;
        _dateController.text = DateFormat('dd.MM.yyyy').format(selected);
      });
    }
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
    return WayPayBottomSheet(
      title: _isEditing ? 'Редактировать инвестора' : 'Новый инвестор',
      onClose: _saving ? null : () => Navigator.pop(context),
      footer: SizedBox(
        width: double.infinity,
        child: DefaultButton(
          text: _saving ? 'Сохранение…' : 'Сохранить',
          isPrimary: true,
          onPressed: _saving ? null : _submit,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalTextField(controller: _nicknameController, label: 'Никнейм'),
          const SizedBox(height: 14),
          ModalTextField(controller: _fullNameController, label: 'ФИО'),
          const SizedBox(height: 14),
          ModalTextField(
            controller: _phoneController,
            label: 'Телефон',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          ModalTextField(
            controller: _pieController,
            label: 'Доля инвестора, %',
            keyboardType: TextInputType.number,
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 14),
            ModalTextField(
              controller: _investmentController,
              label: 'Начальная инвестиция, ₽',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ModalTextField(
            controller: _dateController,
            label: 'Дата окончания договора',
            readOnly: true,
            onTap: _saving ? null : _pickDate,
            suffixIcon: const WayPayCalendarIcon(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: AppStyle.manrope(
                  size: 13,
                  weight: FontWeight.w500,
                  color: const Color(AppColors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/core/di/dependency_injection.dart';
import 'package:waypay_mobile/features/investors/data/data_sources/investors_remote_data_source.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_cash_position_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/data/models/move_cash_position_request.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

/// Перевод кассы инвестора: отдельная касса <-> пул.
class MoveCashPositionSheet extends StatefulWidget {
  const MoveCashPositionSheet({
    super.key,
    required this.investorId,
    required this.investorName,
    this.currentPosition,
  });

  final int investorId;
  final String investorName;
  final InvestorCashPositionModel? currentPosition;

  @override
  State<MoveCashPositionSheet> createState() => _MoveCashPositionSheetState();
}

class _MoveCashPositionSheetState extends State<MoveCashPositionSheet> {
  final TextEditingController _dateController = TextEditingController();

  InvestorCashPositionType _type = InvestorCashPositionType.single;
  DateTime _date = DateTime.now();
  int? _poolId;
  List<InvestorPoolModel> _pools = const [];
  bool _isLoadingPools = false;
  bool _isSaving = false;
  String? _poolsError;

  @override
  void initState() {
    super.initState();
    // По умолчанию предлагаем перевести в противоположную позицию.
    final current = widget.currentPosition?.position;
    _type = current == InvestorCashPositionType.pool
        ? InvestorCashPositionType.single
        : InvestorCashPositionType.pool;
    _date = DateTime.now();
    _dateController.text = DateFormat('dd.MM.yyyy').format(_date);
    if (_type == InvestorCashPositionType.pool) _loadPools();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadPools() async {
    if (_pools.isNotEmpty || _isLoadingPools) return;
    setState(() {
      _isLoadingPools = true;
      _poolsError = null;
    });
    try {
      final result = await getIt<InvestorsRemoteDataSource>().getInvestorPools(
        page: 1,
        pageSize: 100,
      );
      if (!mounted) return;
      setState(() {
        _pools = result.items;
        _isLoadingPools = false;
        if (_poolId == null && _pools.isNotEmpty) _poolId = _pools.first.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPools = false;
        _poolsError = 'Не удалось загрузить пулы: $e';
      });
    }
  }

  Future<void> _pickDate() async {
    await showDialog(
      context: context,
      builder: (ctx) => CustomCalendar(
        initialDate: _date,
        prefix: 'Дата перевода:',
        onDateSelected: (date) {
          setState(() {
            _date = date;
            _dateController.text = DateFormat('dd.MM.yyyy').format(date);
          });
        },
      ),
    );
  }

  bool get _canSave {
    if (_isSaving) return false;
    if (_type == InvestorCashPositionType.pool) return _poolId != null;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      await getIt<InvestorsRemoteDataSource>().moveCashPosition(
        MoveCashPositionRequest(
          investorId: widget.investorId,
          newPositionType: _type,
          poolId: _type == InvestorCashPositionType.pool ? _poolId : null,
          // Дата без времени: полночь UTC, иначе сервер сдвинет день.
          date: DateTime.utc(_date.year, _date.month, _date.day),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAppMessage(context, '$e', type: AppMessageType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WayPayBottomSheet(
      title: 'Перевести кассу',
      subtitle: widget.investorName,
      onClose: _isSaving ? () {} : () => Navigator.of(context).pop(),
      footer: SizedBox(
        width: double.infinity,
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : DefaultButton(
                text: 'Перевести',
                isPrimary: true,
                onPressed: _canSave ? _save : null,
              ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WayPaySectionHeader(title: 'Куда перевести'),
          const SizedBox(height: 8),
          for (final type in InvestorCashPositionType.values)
            CustomRadioButton(
              value: true,
              groupValue: _type == type,
              label: type.title,
              onChanged: _isSaving
                  ? (_) {}
                  : (_) {
                      setState(() => _type = type);
                      if (type == InvestorCashPositionType.pool) _loadPools();
                    },
            ),
          if (_type == InvestorCashPositionType.pool) ...[
            const SizedBox(height: 8),
            if (_isLoadingPools)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_poolsError != null)
              Text(
                _poolsError!,
                style: AppStyle.manrope(
                  size: 13,
                  weight: FontWeight.w500,
                  color: const Color(AppColors.red),
                ),
              )
            else if (_pools.isEmpty)
              const WayPayEmptyState(title: 'У компании нет пулов')
            else
              WayPayDropdownField<int>(
                value: _poolId,
                label: 'Пул',
                items: _pools
                    .map(
                      (pool) => DropdownMenuItem<int>(
                        value: pool.id,
                        child: Text(pool.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _poolId = value),
              ),
          ],
          const SizedBox(height: 16),
          ModalTextField(
            controller: _dateController,
            label: 'Дата перевода',
            hintText: 'Выберите дату',
            readOnly: true,
            onTap: _isSaving ? null : _pickDate,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

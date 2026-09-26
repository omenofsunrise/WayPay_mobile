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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Перевести кассу',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.black),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.investorName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Куда перевести',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.uiBorder),
                  ),
                ),
                const SizedBox(height: 8),
                for (final type in InvestorCashPositionType.values)
                  _PositionOption(
                    title: type.title,
                    selected: _type == type,
                    onTap: _isSaving
                        ? null
                        : () {
                            setState(() => _type = type);
                            if (type == InvestorCashPositionType.pool) {
                              _loadPools();
                            }
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
                      style: const TextStyle(color: Color(AppColors.red)),
                    )
                  else if (_pools.isEmpty)
                    const Text(
                      'У компании нет пулов',
                      style: TextStyle(color: Color(AppColors.uiBorder)),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _poolId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Пул',
                        border: OutlineInputBorder(),
                      ),
                      items: _pools
                          .map(
                            (pool) => DropdownMenuItem<int>(
                              value: pool.id,
                              child: Text(
                                pool.name,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : DefaultButton(
                          text: 'Перевести',
                          isPrimary: true,
                          onPressed: _canSave ? _save : null,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionOption extends StatelessWidget {
  const _PositionOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
              color: selected
                  ? const Color(AppColors.primary)
                  : const Color(AppColors.uiBorder),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(AppColors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

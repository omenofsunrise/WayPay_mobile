import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/buttons/default_button.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay/features/credit/data/models/get_query_credits.dart';
import 'package:waypay/core/widgets/inputs/custom_input.dart';
import 'package:waypay/core/widgets/inputs/date_input.dart';

class CreditFilters extends StatefulWidget {
  final bool showIncomeFilters;
  final bool showClientInvestorFilters;
  final GetCreditsQuery? initialFilters;

  const CreditFilters({
    super.key,
    this.showIncomeFilters = true,
    this.showClientInvestorFilters = true,
    this.initialFilters,
  });

  @override
  State<CreditFilters> createState() => _CreditFiltersState();
}

class _CreditFiltersState extends State<CreditFilters> {
  final _creditIdController = TextEditingController();
  final _investorController = TextEditingController();
  final _fioController = TextEditingController();
  final _incomeRubFromController = TextEditingController();
  final _incomeRubToController = TextEditingController();
  final _incomePercFromController = TextEditingController();
  final _incomePercToController = TextEditingController();

  DateTime? _dateFrom;
  DateTime? _dateTo;
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFromExistingFilters();
  }

  void _initializeFromExistingFilters() {
    final initial = widget.initialFilters;
    if (initial != null) {
      if (initial.creditId != null) {
        _creditIdController.text = initial.creditId.toString();
      }
      if (initial.investorNickname != null) {
        _investorController.text = initial.investorNickname!;
      }
      if (initial.clientFullname != null) {
        _fioController.text = initial.clientFullname!;
      }
      if (initial.rublesIncomeFrom != null) {
        _incomeRubFromController.text = initial.rublesIncomeFrom.toString();
      }
      if (initial.rublesIncomeTo != null) {
        _incomeRubToController.text = initial.rublesIncomeTo.toString();
      }
      if (initial.percentsIncomeFrom != null) {
        _incomePercFromController.text = initial.percentsIncomeFrom.toString();
      }
      if (initial.percentsIncomeTo != null) {
        _incomePercToController.text = initial.percentsIncomeTo.toString();
      }

      _dateFrom = initial.dateFrom;
      _dateTo = initial.dateTo;
      if (_dateFrom != null) {
        _dateFromController.text = DateFormat('dd.MM.yyyy').format(_dateFrom!);
      }
      if (_dateTo != null) {
        _dateToController.text = DateFormat('dd.MM.yyyy').format(_dateTo!);
      }
    }
  }

  void _applyFilters() {
    if (_dateFrom != null && _dateTo != null && _dateFrom!.isAfter(_dateTo!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Дата "От" не может быть больше даты "До"')),
      );
      return;
    }

    final bloc = context.read<CreditBloc>();
    bloc.add(
      LoadCreditsEvent(
        refresh: true,
        query: GetCreditsQuery(
          creditId: _creditIdController.text.isNotEmpty
              ? int.tryParse(_creditIdController.text)
              : null,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          investorNickname:
              widget.showClientInvestorFilters &&
                  _investorController.text.isNotEmpty
              ? _investorController.text
              : null,
          clientFullname:
              widget.showClientInvestorFilters && _fioController.text.isNotEmpty
              ? _fioController.text
              : null,
          rublesIncomeFrom: _incomeRubFromController.text.isNotEmpty
              ? double.tryParse(_incomeRubFromController.text)
              : null,
          rublesIncomeTo: _incomeRubToController.text.isNotEmpty
              ? double.tryParse(_incomeRubToController.text)
              : null,
          percentsIncomeFrom: _incomePercFromController.text.isNotEmpty
              ? double.tryParse(_incomePercFromController.text)
              : null,
          percentsIncomeTo: _incomePercToController.text.isNotEmpty
              ? double.tryParse(_incomePercToController.text)
              : null,
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _creditIdController.clear();
      _investorController.clear();
      _fioController.clear();
      _incomeRubFromController.clear();
      _incomeRubToController.clear();
      _incomePercFromController.clear();
      _incomePercToController.clear();
      _dateFrom = null;
      _dateTo = null;
      _dateFromController.clear();
      _dateToController.clear();
    });
  }

  @override
  void dispose() {
    _creditIdController.dispose();
    _investorController.dispose();
    _fioController.dispose();
    _incomeRubFromController.dispose();
    _incomeRubToController.dispose();
    _incomePercFromController.dispose();
    _incomePercToController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Фильтры',
                      textAlign: TextAlign.left,
                      style: AppStyle.manrope(
                        size: 20,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomInput(
                controller: _creditIdController,
                label: '№ Договора',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),

              _buildDateRangeRow(),

              if (widget.showClientInvestorFilters) ...[
                const SizedBox(height: 8),
                CustomInput(controller: _investorController, label: 'Инвестор'),
                const SizedBox(height: 8),
                CustomInput(
                  controller: _fioController,
                  label: 'ФИО',
                  inputType: InputType.fullname,
                ),
              ],
              if (widget.showIncomeFilters) ...[
                const SizedBox(height: 8),
                _buildRangeGroup(
                  label: 'Доход, ₽',
                  from: _incomeRubFromController,
                  to: _incomeRubToController,
                ),
                const SizedBox(height: 8),
                _buildRangeGroup(
                  label: 'Доход, %',
                  from: _incomePercFromController,
                  to: _incomePercToController,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DefaultButton(
                      text: 'Очистить',
                      isGreen: false,
                      onPressed: _clearFilters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DefaultButton(
                      text: 'Применить',
                      isGreen: true,
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DateInput(
                  controller: _dateFromController,
                  label: 'От',
                  initialDate: _dateFrom,
                  onDateSelected: (date) {
                    setState(() {
                      _dateFrom = date;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DateInput(
                  controller: _dateToController,
                  label: 'До',
                  initialDate: _dateTo,
                  onDateSelected: (date) {
                    setState(() {
                      _dateTo = date;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeGroup({
    required String label,
    required TextEditingController from,
    required TextEditingController to,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomInput(
                  controller: from,
                  label: 'От',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomInput(
                  controller: to,
                  label: 'До',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

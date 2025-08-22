import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay/core/theme/app_colors.dart';
import 'package:waypay/core/theme/app_style.dart';
import 'package:waypay/core/widgets/default_button.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay/features/credit/data/models/get_query_credits.dart';

class CreditFilters extends StatefulWidget {
  final bool showIncomeFilters;
  final bool showClientInvestorFilters;

  const CreditFilters({super.key, this.showIncomeFilters = true, this.showClientInvestorFilters = true});

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

  void _applyFilters() {
    final bloc = context.read<CreditBloc>();
    bloc.add(
      LoadCreditsEvent(
        refresh: true,
        query: GetCreditsQuery(
          creditId: _creditIdController.text.isNotEmpty ? int.tryParse(_creditIdController.text) : null,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          investorNickname: widget.showClientInvestorFilters && _investorController.text.isNotEmpty
              ? _investorController.text
              : null,
          clientFullname: widget.showClientInvestorFilters && _fioController.text.isNotEmpty
              ? _fioController.text
              : null,
          rublesIncomeFrom: _incomeRubFromController.text.isNotEmpty
              ? double.tryParse(_incomeRubFromController.text)
              : null,
          rublesIncomeTo: _incomeRubToController.text.isNotEmpty ? double.tryParse(_incomeRubToController.text) : null,
          percentsIncomeFrom: _incomePercFromController.text.isNotEmpty
              ? double.tryParse(_incomePercFromController.text)
              : null,
          percentsIncomeTo: _incomePercToController.text.isNotEmpty
              ? double.tryParse(_incomePercToController.text)
              : null,
        ),
      ),
    );
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
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'Фильтры',
                  textAlign: TextAlign.center,
                  style: AppStyle.manrope(size: 20, weight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _buildStyledTextField(
            controller: _creditIdController,
            label: 'Номер Договора',
            keyboardType: TextInputType.number,
          ),
          _buildStyledDatePicker('От: Дата', _dateFrom, true),
          _buildStyledDatePicker('До: Дата', _dateTo, false),

          if (widget.showClientInvestorFilters) ...[
            _buildStyledTextField(controller: _investorController, label: 'Инвестор'),
            _buildStyledTextField(controller: _fioController, label: 'ФИО'),
          ],
          if (widget.showIncomeFilters) ...[
            _buildRangeGroupStyled(label: 'Доход, ₽', from: _incomeRubFromController, to: _incomeRubToController),
            _buildRangeGroupStyled(label: 'Доход, %', from: _incomePercFromController, to: _incomePercToController),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DefaultButton(text: 'Очистить', isGreen: false, onPressed: _clearFilters),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultButton(
                  text: 'Применить',
                  isGreen: true,
                  onPressed: () {
                    _applyFilters();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(AppColors.primary)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(AppColors.primary), width: 2),
              ),
            ),
            style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDatePicker(String label, DateTime? date, bool isFrom) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _pickDate(isFrom: isFrom),
            child: InputDecorator(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(AppColors.primary)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(AppColors.primary), width: 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date != null ? DateFormat('dd.MM.yyyy').format(date) : '',
                    style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
                  ),
                  Icon(Icons.calendar_month, color: Color(AppColors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeGroupStyled({
    required String label,
    required TextEditingController from,
    required TextEditingController to,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyle.manrope(size: 14, weight: FontWeight.w400)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStyledTextField(controller: from, label: 'От'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStyledTextField(controller: to, label: 'До'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

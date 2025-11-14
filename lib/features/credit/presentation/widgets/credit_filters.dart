import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waypay_mobile/core/theme/app_style.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/features/credit/data/objectType/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/credit/data/objectType/models/object_type_model.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_input.dart';
import 'package:waypay_mobile/core/widgets/inputs/date_input.dart';
import 'package:waypay_mobile/core/widgets/inputs/custom_select.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/object_type_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/object_type_event.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/object_type_state.dart';

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

  ObjectTypeModel? _selectedObjectType;
  bool _isObjectTypesLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFromExistingFilters();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadObjectTypes();
    });
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

  void _loadObjectTypes() {
    if (_isObjectTypesLoading) return;

    setState(() {
      _isObjectTypesLoading = true;
    });

    final objectTypeBloc = context.read<ObjectTypeBloc>();
    objectTypeBloc.add(
      LoadObjectTypesEvent(
        refresh: true,
        query: GetObjectTypesQuery(
          page: 1,
          pageSize: 100,
          entityType: 'Credit',
        ),
      ),
    );
  }

  void _applyFilters() {
    if (_dateFrom != null && _dateTo != null && _dateFrom!.isAfter(_dateTo!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Дата "От" не может быть больше даты "До"'),
        ),
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
          creditTypeId: _selectedObjectType?.id,
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
      _selectedObjectType = null;
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            _buildObjectTypeSection(),
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
    );
  }

  Widget _buildObjectTypeSection() {
    return BlocConsumer<ObjectTypeBloc, ObjectTypeState>(
      listener: (context, state) {
        if (state is ObjectTypeLoaded || state is ObjectTypeError) {
          setState(() {
            _isObjectTypesLoading = false;
          });
        }
      },
      builder: (context, state) {
        List<ObjectTypeModel> objectTypes = [];

        if (state is ObjectTypeLoaded) {
          objectTypes = state.objectTypes;
        } else if (state is ObjectTypeError) {
          // Можно показать сообщение об ошибке
          print('Ошибка загрузки типов объектов: ${state.message}');
        }

        final options = objectTypes
            .map(
              (type) => CustomSelectOption<ObjectTypeModel?>(
                value: type,
                label: type.name,
              ),
            )
            .toList();

        options.insert(
          0,
          CustomSelectOption<ObjectTypeModel?>(value: null, label: 'Все'),
        );

        if (_isObjectTypesLoading || state is ObjectTypeLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Каталог',
                style: AppStyle.manrope(size: 14, weight: FontWeight.w400),
              ),
              const SizedBox(height: 8),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
          );
        }

        return CustomSelect<ObjectTypeModel?>(
          placeholder: 'Выберите каталог',
          options: options,
          value: _selectedObjectType,
          onChange: (ObjectTypeModel? value) {
            setState(() {
              _selectedObjectType = value;
            });
          },
        );
      },
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/objectType/data/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_event.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_state.dart';

class CreditFiltersSheet extends StatelessWidget {
  const CreditFiltersSheet({super.key, this.initialFilters});

  final GetCreditsQuery? initialFilters;

  @override
  Widget build(BuildContext context) {
    return FilterSheet(
      child: _CreditFiltersForm(initialFilters: initialFilters),
    );
  }
}

class _CreditFiltersForm extends StatefulWidget {
  const _CreditFiltersForm({this.initialFilters});

  final GetCreditsQuery? initialFilters;

  @override
  State<_CreditFiltersForm> createState() => _CreditFiltersFormState();
}

class _CreditFiltersFormState extends State<_CreditFiltersForm> {
  final _contractController = TextEditingController();
  final _clientController = TextEditingController();
  final _investorController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _catalogController = TextEditingController();
  final _addressController = TextEditingController();
  final _createdFromController = TextEditingController();
  final _createdToController = TextEditingController();

  DateTime? _dateFrom;
  DateTime? _dateTo;
  DateTime? _createdFrom;
  DateTime? _createdTo;
  bool _isFavourite = false;
  bool _debt = false;
  bool _inDebt = false;
  bool _terminated = false;
  bool _myCredits = false;
  ObjectTypeModel? _selectedCatalog;
  bool _showCatalogOptions = false;
  int? _initialCatalogId;

  final _dateFormat = DateFormat('dd.MM.yyyy');

  List<TextEditingController> get _controllers => [
    _contractController,
    _clientController,
    _investorController,
    _dateFromController,
    _dateToController,
    _catalogController,
    _addressController,
    _createdFromController,
    _createdToController,
  ];

  @override
  void initState() {
    super.initState();
    _initialCatalogId = widget.initialFilters?.creditTypeId;
    _applyInitialValues();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadObjectTypes();
    });
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

  bool get _hasAnyValue =>
      _controllers.any((c) => c.text.trim().isNotEmpty) ||
      _selectedCatalog != null ||
      _isFavourite ||
      _debt ||
      _inDebt ||
      _terminated ||
      _myCredits;

  void _applyInitialValues() {
    final filters = widget.initialFilters;
    if (filters == null) return;

    if (filters.creditId != null) {
      _contractController.text = filters.creditId.toString();
    }
    if ((filters.clientFullname ?? '').isNotEmpty) {
      _clientController.text = filters.clientFullname!;
    }
    if ((filters.investorNickname ?? '').isNotEmpty) {
      _investorController.text = filters.investorNickname!;
    }

    if ((filters.name ?? '').isNotEmpty) {
      _contractController.text = filters.name!;
    }
    if ((filters.clientAddress ?? '').isNotEmpty) {
      _addressController.text = filters.clientAddress!;
    }

    _dateFrom = filters.dateFrom;
    _dateTo = filters.dateTo;
    _dateFromController.text = _formatDate(_dateFrom);
    _dateToController.text = _formatDate(_dateTo);

    _createdFrom = filters.createdAt;
    _createdTo = filters.createdTo;
    _createdFromController.text = _formatDate(_createdFrom);
    _createdToController.text = _formatDate(_createdTo);

    _isFavourite = filters.isFavourite ?? false;
    _debt = filters.debt ?? false;
    _inDebt = filters.inDebt ?? false;
    _terminated = filters.terminated ?? false;
    _myCredits = filters.myCredits ?? false;
  }

  void _loadObjectTypes() {
    final bloc = context.read<ObjectTypeBloc>();
    final state = bloc.state;
    if (state is ObjectTypeLoaded && state.objectTypes.isNotEmpty) {
      _applyCatalogFromState(state.objectTypes);
      return;
    }
    bloc.add(
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

  void _applyCatalogFromState(List<ObjectTypeModel> types) {
    if (_initialCatalogId == null || _selectedCatalog != null) return;
    for (final type in types) {
      if (type.id == _initialCatalogId) {
        setState(() {
          _selectedCatalog = type;
          _catalogController.text = type.name;
          _initialCatalogId = null;
        });
        break;
      }
    }
  }

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

  Future<void> _pickCreatedDate({required bool isFrom}) async {
    final initialDate = isFrom
        ? _createdFrom ?? DateTime.now()
        : _createdTo ?? _createdFrom ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _createdFrom = picked;
          _createdFromController.text = _formatDate(picked);
        } else {
          _createdTo = picked;
          _createdToController.text = _formatDate(picked);
        }
      });
    }
  }

  GetCreditsQuery _buildFilters() {
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    return GetCreditsQuery(
      // Бэкенд в ApplyNameFilter ищет и по номеру, и по названию,
      // поэтому числовой creditId отдельно не нужен.
      name: text(_contractController),
      clientFullname: text(_clientController),
      investorNickname: text(_investorController),
      clientAddress: text(_addressController),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      createdAt: _createdFrom,
      createdTo: _createdTo,
      creditTypeId: _selectedCatalog?.id,
      isFavourite: _isFavourite ? true : null,
      debt: _debt ? true : null,
      inDebt: _inDebt ? true : null,
      terminated: _terminated ? true : null,
      myCredits: _myCredits ? true : null,
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 22,
              color: value
                  ? const Color(AppColors.primary)
                  : const Color(AppColors.uiBorder),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
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

  void _toggleCatalogOptions() {
    FocusScope.of(context).unfocus();
    setState(() => _showCatalogOptions = !_showCatalogOptions);
  }

  void _selectCatalog(ObjectTypeModel? type) {
    setState(() {
      _selectedCatalog = type;
      _catalogController.text = type?.name ?? '';
      _showCatalogOptions = false;
    });
  }

  Widget _buildCatalogField() {
    return BlocBuilder<ObjectTypeBloc, ObjectTypeState>(
      builder: (context, state) {
        if (state is ObjectTypeLoaded) {
          _applyCatalogFromState(state.objectTypes);
        }
        final types = state is ObjectTypeLoaded
            ? state.objectTypes
            : <ObjectTypeModel>[];
        final isLoading = state is ObjectTypeLoading && types.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModalTextField(
              controller: _catalogController,
              label: 'Категория',
              hintText: 'Выберите категорию',
              readOnly: true,
              onTap: () {
                if (types.isEmpty && !isLoading) {
                  _loadObjectTypes();
                }
                _toggleCatalogOptions();
              },
              suffixIcon: Transform.rotate(
                angle: _showCatalogOptions ? 3.1415 : 0,
                child: const Icon(Icons.keyboard_arrow_down),
              ),
              suffixIconConstraints: const BoxConstraints(
                minHeight: 24,
                minWidth: 24,
              ),
            ),
            if (_showCatalogOptions)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD9DDE5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 220),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _buildCatalogOptions(types),
              ),
            if (state is ObjectTypeError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCatalogOptions(List<ObjectTypeModel> types) {
    if (types.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Категории не найдены',
          style: TextStyle(color: Color(AppColors.uiBorder)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: types.length + 1,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          final isSelected = _selectedCatalog == null;
          return ListTile(
            title: const Text('Без категории'),
            onTap: () => _selectCatalog(null),
            trailing: isSelected
                ? const Icon(Icons.check, color: Color(AppColors.primary))
                : null,
          );
        }
        final type = types[index - 1];
        final isSelected = _selectedCatalog?.id == type.id;
        return ListTile(
          title: Text(type.name),
          onTap: () => _selectCatalog(type),
          trailing: isSelected
              ? const Icon(Icons.check, color: Color(AppColors.primary))
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ObjectTypeBloc, ObjectTypeState>(
      listener: (context, state) {
        if (state is ObjectTypeLoaded) {
          _applyCatalogFromState(state.objectTypes);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModalTextField(
            controller: _contractController,
            label: '№ договора',
            hintText: 'Введите номер или название',
          ),
          const SizedBox(height: 16),
          const Text(
            'Дата договора',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.uiBorder),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: _dateFromController,
                  label: 'От',
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  controller: _dateToController,
                  label: 'До',
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          ModalTextField(
            controller: _addressController,
            label: 'Адрес клиента',
            hintText: 'Введите адрес',
          ),
          const SizedBox(height: 12),
          _buildCatalogField(),
          const SizedBox(height: 16),
          const Text(
            'Дата создания',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(AppColors.uiBorder),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: _createdFromController,
                  label: 'От',
                  onTap: () => _pickCreatedDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  controller: _createdToController,
                  label: 'До',
                  onTap: () => _pickCreatedDate(isFrom: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildToggle(
            label: 'Только избранные',
            value: _isFavourite,
            onChanged: (v) => setState(() => _isFavourite = v),
          ),
          _buildToggle(
            label: 'С просрочкой',
            value: _debt,
            onChanged: (v) => setState(() => _debt = v),
          ),
          _buildToggle(
            label: 'В долг',
            value: _inDebt,
            onChanged: (v) => setState(() => _inDebt = v),
          ),
          _buildToggle(
            label: 'Расторгнутые',
            value: _terminated,
            onChanged: (v) => setState(() => _terminated = v),
          ),
          _buildToggle(
            label: 'Только мои',
            value: _myCredits,
            onChanged: (v) => setState(() => _myCredits = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: DefaultButton(
                  text: 'Отменить',
                  color: const Color(0xFFB8BEC8),
                  textColor: const Color(AppColors.black),
                  onPressed: () {
                    Navigator.of(context).pop();
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/features/home/domain/entities/client_application_filters.dart';

class ClientApplicationsFiltersSheet extends StatelessWidget {
  const ClientApplicationsFiltersSheet({
    super.key,
    this.initialFilters,
    this.regions = const [
      'Чеченская республика',
      'Республика Татарстан',
      'Московская область',
    ],
    this.districts = const ['Веденский', 'Грозненский', 'Урус-Мартановский'],
  });

  final ClientApplicationFilters? initialFilters;
  final List<String> regions;
  final List<String> districts;

  @override
  Widget build(BuildContext context) {
    return FilterSheet(
      child: ClientApplicationsFiltersForm(
        initialFilters: initialFilters,
        regions: regions,
        districts: districts,
      ),
    );
  }
}

class ClientApplicationsFiltersForm extends StatefulWidget {
  const ClientApplicationsFiltersForm({
    super.key,
    this.initialFilters,
    required this.regions,
    required this.districts,
  });

  final ClientApplicationFilters? initialFilters;
  final List<String> regions;
  final List<String> districts;

  @override
  State<ClientApplicationsFiltersForm> createState() =>
      _ClientApplicationsFiltersFormState();
}

class _ClientApplicationsFiltersFormState
    extends State<ClientApplicationsFiltersForm> {
  final _minCostController = TextEditingController();
  final _maxCostController = TextEditingController();
  final _minTermController = TextEditingController();
  final _maxTermController = TextEditingController();
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();

  List<TextEditingController> get _controllers => [
    _minCostController,
    _maxCostController,
    _minTermController,
    _maxTermController,
    _regionController,
    _districtController,
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

  void _clearAll() {
    for (final controller in _controllers) {
      controller.clear();
    }
    setState(() {});
  }

  void _onFieldsChanged() => setState(() {});

  bool get _hasAnyValue => _controllers.any((c) => c.text.trim().isNotEmpty);

  void _applyInitialValues() {
    final filters = widget.initialFilters;
    if (filters == null || filters.isEmpty) return;
    _minCostController.text =
        filters.minCost?.toString() ?? _minCostController.text;
    _maxCostController.text =
        filters.maxCost?.toString() ?? _maxCostController.text;
    _minTermController.text =
        filters.minTerm?.toString() ?? _minTermController.text;
    _maxTermController.text =
        filters.maxTerm?.toString() ?? _maxTermController.text;
    _regionController.text = filters.region ?? '';
    _districtController.text = filters.district ?? '';
  }

  ClientApplicationFilters _buildFilters() => ClientApplicationFilters(
    minCost: _parseToInt(_minCostController.text),
    maxCost: _parseToInt(_maxCostController.text),
    minTerm: _parseToInt(_minTermController.text),
    maxTerm: _parseToInt(_maxTermController.text),
    region: _regionController.text.trim().isEmpty
        ? null
        : _regionController.text.trim(),
    district: _districtController.text.trim().isEmpty
        ? null
        : _districtController.text.trim(),
  );

  int? _parseToInt(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<void> _selectRegion() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ClientApplicationsFilterSelector(
        title: 'Регион',
        items: widget.regions,
        selected: _regionController.text,
      ),
    );
    if (selected != null) {
      _regionController.text = selected;
      setState(() {});
    }
  }

  Future<void> _selectDistrict() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ClientApplicationsFilterSelector(
        title: 'Район',
        items: widget.districts,
        selected: _districtController.text,
      ),
    );
    if (selected != null) {
      _districtController.text = selected;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ModalTextField(
                controller: _minCostController,
                label: 'Мин. стоимость',
                hintText: 'Введите сумму',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModalTextField(
                controller: _maxCostController,
                label: 'Макс. стоимость',
                hintText: 'Введите сумму',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ModalTextField(
                controller: _minTermController,
                label: 'Мин. срок месяцев',
                hintText: 'Введите срок',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModalTextField(
                controller: _maxTermController,
                label: 'Макс. срок месяцев',
                hintText: 'Введите срок',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ModalTextField(
          controller: _regionController,
          label: 'Регион',
          readOnly: true,
          hintText: 'Выберите регион',
          suffixIcon: const Icon(
            Icons.expand_more,
            color: Color(AppColors.uiBorder),
          ),
          onTap: _selectRegion,
        ),
        const SizedBox(height: 12),
        ModalTextField(
          controller: _districtController,
          label: 'Район',
          readOnly: true,
          hintText: 'Выберите район',
          suffixIcon: const Icon(
            Icons.expand_more,
            color: Color(AppColors.uiBorder),
          ),
          onTap: _selectDistrict,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: DefaultButton(
                text: 'Сбросить',
                color: const Color(0xFFB8BEC8),
                textColor: const Color(AppColors.black),
                onPressed: _clearAll,
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

class ClientApplicationsFilterSelector extends StatelessWidget {
  const ClientApplicationsFilterSelector({
    super.key,
    required this.title,
    required this.items,
    this.selected,
  });

  final String title;
  final List<String> items;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => ListTile(
                title: Text(item),
                trailing: selected == item
                    ? const Icon(Icons.check, color: Color(AppColors.primary))
                    : null,
                onTap: () => Navigator.of(context).pop(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/default_button.dart';
import 'package:waypay_mobile/core/widgets/custom_tab_switcher.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/core/widgets/inputs/modal_text_field.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/client_application_card.dart';
import 'package:waypay_mobile/routes/routes.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';

class ClientApplicationsScreen extends StatefulWidget {
  const ClientApplicationsScreen({super.key});

  @override
  State<ClientApplicationsScreen> createState() =>
      _ClientApplicationsScreenState();
}

class _ClientApplicationsScreenState extends State<ClientApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final List<ClientApplication> _applications = _mockApplications;
  String _searchQuery = '';
  ClientApplicationFilters? _appliedFilters;
  bool _showSearchHint = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<ClientApplication> _filterApplications({bool onlyMine = false}) {
    final query = _searchQuery.trim().toLowerCase();
    final queryDigits = query.replaceAll(RegExp(r'\D'), '');
    final filters = _appliedFilters;
    final hintNeeded =
        _searchQuery.trim().isNotEmpty &&
        _searchQuery.trim().length < 4 &&
        queryDigits.length < 11;

    final result = _applications.where((application) {
      if (onlyMine && !application.isMine) return false;

      final hasQuery = query.isNotEmpty;
      final matchesName =
          !hasQuery || application.fullName.toLowerCase().contains(query);
      final matchesNumber =
          !hasQuery ||
          application.applicationNumber.toLowerCase().contains(query);
      final matchesProduct =
          !hasQuery || application.productName.toLowerCase().contains(query);
      final matchesDigits =
          hasQuery &&
          queryDigits.isNotEmpty &&
          application.applicationNumber
              .replaceAll(RegExp(r'\D'), '')
              .contains(queryDigits);

      final matchesSearch =
          matchesName || matchesNumber || matchesProduct || matchesDigits;
      if (!matchesSearch) return false;

      if (filters == null || filters.isEmpty) return true;
      return _matchesFilters(application, filters);
    }).toList();

    if (_showSearchHint != hintNeeded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _showSearchHint = hintNeeded);
        }
      });
    }

    return result;
  }

  bool _matchesFilters(
    ClientApplication application,
    ClientApplicationFilters filters,
  ) {
    final cost = _parseDigits(application.amount);
    final term = _parseDigits(application.term);

    if (filters.minCost != null && (cost == null || cost < filters.minCost!)) {
      return false;
    }
    if (filters.maxCost != null && (cost == null || cost > filters.maxCost!)) {
      return false;
    }
    if (filters.minTerm != null && (term == null || term < filters.minTerm!)) {
      return false;
    }
    if (filters.maxTerm != null && (term == null || term > filters.maxTerm!)) {
      return false;
    }
    if (filters.region != null &&
        filters.region!.isNotEmpty &&
        application.region.toLowerCase() != filters.region!.toLowerCase()) {
      return false;
    }
    if (filters.district != null &&
        filters.district!.isNotEmpty &&
        application.district.toLowerCase() != filters.district!.toLowerCase()) {
      return false;
    }
    return true;
  }

  int? _parseDigits(String source) {
    final digits = source.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    BottomNavController.instance.hide();
    final result = await showModalBottomSheet<ClientApplicationFilters>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _ClientApplicationsFiltersSheet(initialFilters: _appliedFilters),
    );
    BottomNavController.instance.show();
    if (result != null) {
      setState(() {
        _appliedFilters = result.isEmpty ? null : result;
      });
    }
  }

  void _clearAppliedFilters() {
    setState(() => _appliedFilters = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(title: 'Заявки', showBackButton: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _searchController,
                      hintText: 'Поиск',
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FilterButton(
                    onTap: _openFilters,
                    isActive: _appliedFilters != null,
                  ),
                ],
              ),
              if (_showSearchHint)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Введите минимум 4 символа ФИО или полный номер телефона',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(AppColors.darkGrey),
                    ),
                  ),
                ),
              if (_appliedFilters != null && !_appliedFilters!.isEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _clearAppliedFilters,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Сбросить фильтры',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(AppColors.primary),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.close,
                        size: 18,
                        color: Color(AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              CustomTabSwitcher(
                controller: _tabController,
                tabs: const ['Все заявки', 'Мои заявки'],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ApplicationsListView(applications: _filterApplications()),
                    _ApplicationsListView(
                      applications: _filterApplications(onlyMine: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientApplication {
  const ClientApplication({
    required this.fullName,
    required this.applicationNumber,
    required this.term,
    required this.productName,
    required this.amount,
    required this.region,
    required this.district,
    required this.managerName,
    required this.firstPayment,
    required this.issueDate,
    this.isMine = false,
  });

  final String fullName;
  final String applicationNumber;
  final String term;
  final String productName;
  final String amount;
  final String region;
  final String district;
  final String managerName;
  final String firstPayment;
  final String issueDate;
  final bool isMine;
}

class ClientApplicationFilters {
  const ClientApplicationFilters({
    this.minCost,
    this.maxCost,
    this.minTerm,
    this.maxTerm,
    this.region,
    this.district,
  });

  final int? minCost;
  final int? maxCost;
  final int? minTerm;
  final int? maxTerm;
  final String? region;
  final String? district;

  bool get isEmpty =>
      minCost == null &&
      maxCost == null &&
      minTerm == null &&
      maxTerm == null &&
      (region == null || region!.isEmpty) &&
      (district == null || district!.isEmpty);
}

const List<ClientApplication> _mockApplications = [
  ClientApplication(
    fullName: 'Мирошниченко Владислава Филипповна',
    applicationNumber: '№ 234',
    term: '24 месяца',
    productName: 'Iphone 17 Pro MAX 256GB',
    amount: '124 000₽',
    region: 'Чеченская республика',
    district: 'Веденский',
    managerName: 'Мирошниченко Владислава Филипповна',
    firstPayment: '0₽',
    issueDate: '12.10.2025',
    isMine: true,
  ),
  ClientApplication(
    fullName: 'Антонов Сергей Леонидович',
    applicationNumber: '№ 235',
    term: '18 месяцев',
    productName: 'MacBook Air 15"',
    amount: '215 000₽',
    region: 'Республика Татарстан',
    district: 'Грозненский',
    managerName: 'Александр Громов',
    firstPayment: '25 000₽',
    issueDate: '05.09.2025',
  ),
  ClientApplication(
    fullName: 'Семенова Алина Викторовна',
    applicationNumber: '№ 236',
    term: '36 месяцев',
    productName: 'Volkswagen Polo',
    amount: '980 000₽',
    region: 'Чеченская республика',
    district: 'Урус-Мартановский',
    managerName: 'Егор Степанов',
    firstPayment: '150 000₽',
    issueDate: '01.08.2025',
    isMine: true,
  ),
  ClientApplication(
    fullName: 'Громов Михаил Сергеевич',
    applicationNumber: '№ 237',
    term: '12 месяцев',
    productName: 'Ipad Air 128GB',
    amount: '82 000₽',
    region: 'Московская область',
    district: 'Грозненский',
    managerName: 'Ирина Логинова',
    firstPayment: '10 000₽',
    issueDate: '18.07.2025',
  ),
];

class _ApplicationsListView extends StatelessWidget {
  const _ApplicationsListView({required this.applications});

  final List<ClientApplication> applications;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const _EmptyApplicationsView();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final application = applications[index];
        return ClientApplicationCard(
          fullName: application.fullName,
          applicationNumber: application.applicationNumber,
          term: application.term,
          productName: application.productName,
          amount: application.amount,
          onTap: () {
            context.pushNamed(
              Routes.clientApplicationDetailScreen.toName,
              extra: application,
            );
          },
        );
      },
    );
  }
}

class _EmptyApplicationsView extends StatelessWidget {
  const _EmptyApplicationsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Color(AppColors.darkGrey),
          ),
          SizedBox(height: 12),
          Text(
            'Нет заявок по текущим фильтрам',
            style: TextStyle(
              fontSize: 15,
              color: Color(AppColors.darkGrey),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ClientApplicationsFiltersSheet extends StatelessWidget {
  const _ClientApplicationsFiltersSheet({this.initialFilters});

  final ClientApplicationFilters? initialFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
      ),
      child: _FiltersForm(initialFilters: initialFilters),
    );
  }
}

class _FiltersForm extends StatefulWidget {
  const _FiltersForm({this.initialFilters});

  final ClientApplicationFilters? initialFilters;

  @override
  State<_FiltersForm> createState() => _FiltersFormState();
}

class _FiltersFormState extends State<_FiltersForm> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Фильтры',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
            color: Color(AppColors.darkGrey),
          ),
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              builder: (_) => _SimpleSelector(
                title: 'Регион',
                items: [
                  'Чеченская республика',
                  'Республика Татарстан',
                  'Московская область',
                ],
                selected: _regionController.text,
              ),
            );
            if (selected != null) {
              _regionController.text = selected;
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 12),
        ModalTextField(
          controller: _districtController,
          label: 'Район',
          readOnly: true,
          hintText: 'Выберите район',
          suffixIcon: const Icon(
            Icons.expand_more,
            color: Color(AppColors.darkGrey),
          ),
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              builder: (_) => _SimpleSelector(
                title: 'Район',
                items: ['Веденский', 'Грозненский', 'Урус-Мартановский'],
                selected: _districtController.text,
              ),
            );
            if (selected != null) {
              _districtController.text = selected;
              setState(() {});
            }
          },
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

class _SimpleSelector extends StatelessWidget {
  const _SimpleSelector({
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

class _FilterButton extends StatefulWidget {
  const _FilterButton({required this.onTap, required this.isActive});

  final Future<void> Function() onTap;
  final bool isActive;

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton> {
  bool _isOpen = false;

  Future<void> _openFilters() async {
    setState(() => _isOpen = true);
    await widget.onTap();
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool highlight = _isOpen || widget.isActive;
    final background = highlight
        ? const Color(AppColors.primary)
        : Colors.white;
    final iconColor = highlight
        ? const Color(0xFFB8BEC8)
        : const Color(0xFF6B717C);

    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openFilters,
          child: Center(
            child: SvgPicture.asset(SvgIcons.filter, color: iconColor),
          ),
        ),
      ),
    );
  }
}

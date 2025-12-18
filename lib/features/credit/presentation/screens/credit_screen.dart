import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_card.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';

import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_state.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_filters_sheet.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_tab.dart';
import 'package:waypay_mobile/features/objectType/data/models/get_object_types_query.dart';
import 'package:waypay_mobile/features/objectType/data/models/object_type_model.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_event.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_state.dart';
import 'package:waypay_mobile/features/profile/data/models/employee.dart';
import 'package:waypay_mobile/routes/routes.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  CreditTab _selectedTab = CreditTab.all;
  GetCreditsQuery? _appliedFilters;
  ObjectTypeModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  void _loadCredits({bool refresh = true, int? page, String? search}) {
    final query = _composeQuery(search: search, page: page);
    context.read<CreditBloc>().add(
      LoadCreditsEvent(refresh: refresh, query: query, page: page),
    );
  }

  GetCreditsQuery _composeQuery({String? search, int? page}) {
    final trimmedSearch =
        search ??
        (_searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim());
    final filters = _appliedFilters;
    final int? categoryId = _selectedCategory?.id ?? filters?.creditTypeId;

    return GetCreditsQuery(
      search: trimmedSearch,
      isFavourite: _selectedTab == CreditTab.favourite ? true : null,
      isActive: _selectedTab == CreditTab.archived ? false : null,
      debt: _selectedTab == CreditTab.debtors ? true : null,
      creditId: filters?.creditId,
      dateFrom: filters?.dateFrom,
      dateTo: filters?.dateTo,
      investorNickname: filters?.investorNickname,
      clientFullname: filters?.clientFullname,
      creditTypeId: categoryId,
      page: page,
    );
  }

  bool _hasFilterValues(
    GetCreditsQuery? query, {
    ObjectTypeModel? categoryOverride,
  }) {
    final categoryValue = categoryOverride ?? _selectedCategory;
    final hasQueryValues =
        query != null &&
        (query.creditId != null ||
            query.dateFrom != null ||
            query.dateTo != null ||
            (query.investorNickname != null &&
                query.investorNickname!.isNotEmpty) ||
            (query.clientFullname != null &&
                query.clientFullname!.isNotEmpty) ||
            query.creditTypeId != null);
    return hasQueryValues || categoryValue != null;
  }

  void _clearFilters() {
    if (!_hasFilterValues(_appliedFilters)) return;
    setState(() => _appliedFilters = null);
    _selectedCategory = null;
    _loadCredits();
  }

  void _toggleFavourite(int creditId) {
    context.read<CreditBloc>().add(ToggleFavouriteEvent(creditId: creditId));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterModal(BuildContext context) async {
    final objectTypeBloc = BlocProvider.of<ObjectTypeBloc>(
      context,
      listen: false,
    );

    final result = await showModalBottomSheet<GetCreditsQuery>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withOpacity(0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: objectTypeBloc,
          child: CreditFiltersSheet(initialFilters: _appliedFilters),
        );
      },
    );

    if (result != null) {
      final hasValues = _hasFilterValues(result, categoryOverride: null);
      setState(() {
        _selectedCategory = null;
        _appliedFilters = hasValues ? result : null;
      });
      _loadCredits();
    }
  }

  Future<void> _openCreditTabSheet() async {
    final objectTypeBloc = context.read<ObjectTypeBloc>();
    objectTypeBloc.add(
      LoadObjectTypesEvent(
        refresh: true,
        query: GetObjectTypesQuery(
          page: 1,
          pageSize: 100,
          entityType: 'CreditTab',
        ),
      ),
    );

    final result = await showModalBottomSheet<_CreditTabSelectionResult>(
      context: context,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withOpacity(0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: objectTypeBloc,
        child: _CreditTabSheet(
          selectedTab: _selectedTab,
          selectedCategory: _selectedCategory,
        ),
      ),
    );

    if (result == null) return;

    if (result.category != null) {
      setState(() {
        _selectedCategory = result.category;
        _selectedTab = CreditTab.all;
      });
      _loadCredits();
      return;
    }

    if (result.tab != null && result.tab != _selectedTab) {
      setState(() {
        _selectedTab = result.tab!;
        _selectedCategory = null;
      });
      _loadCredits();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmed = value.trim();
      _loadCredits(search: trimmed.isNotEmpty ? trimmed : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: ValueListenableBuilder<EmployeeRole?>(
                  valueListenable: UserStorage().roleNotifier,
                  builder: (context, role, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Header(
                                title: 'Договоры',
                                showBackButton: true,
                                showNotifications: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AddButton(
                              onPressed: () {
                                context.pushNamed(
                                  Routes.newCreditDetailsScreen.toName,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        if (_hasFilterValues(_appliedFilters)) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _clearFilters,
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
                        const SizedBox(height: 4),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
          body: BlocBuilder<CreditBloc, CreditState>(
            builder: (context, state) {
              if (state is CreditLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is CreditError) {
                return Center(child: Text('Ошибка: ${state.message}'));
              }
              if (state is CreditLoaded) {
                if (state.credits.isEmpty) {
                  return const Center(child: Text('Договоры не найдены'));
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CreditList(
                    credits: state.credits,
                    currentPage: state.currentPage,
                    totalPages: state.totalPages,
                    onRefresh: () async => _loadCredits(),
                    onLoadMore: (page) => _loadCredits(page: page),
                    onFavouriteToggle: _toggleFavourite,
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasCustomTab =
        _selectedTab != CreditTab.all || _selectedCategory != null;
    return Row(
      children: [
        Expanded(
          child: SearchField(
            controller: _searchController,
            hintText: 'Поиск',
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchChanged,
          ),
        ),
        const SizedBox(width: 12),
        FilterButton(
          onTap: _openCreditTabSheet,
          isActive: hasCustomTab,
          iconAsset: _selectedCategory != null
              ? SvgIcons.filter
              : _selectedTab.iconPath,
          activeIconColor: Colors.white,
        ),
        const SizedBox(width: 12),
        FilterButton(
          onTap: () => _openFilterModal(context),
          isActive: _hasFilterValues(_appliedFilters),
        ),
      ],
    );
  }
}

class _CreditTabSheet extends StatelessWidget {
  const _CreditTabSheet({required this.selectedTab, this.selectedCategory});

  final CreditTab selectedTab;
  final ObjectTypeModel? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      CreditTab.all,
      CreditTab.favourite,
      CreditTab.archived,
      CreditTab.debtors,
    ];
    return FilterSheet(
      title: 'Сортировка',
      keepHeaderPinned: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...tabs.map((tab) {
            final isActive = tab == selectedTab && selectedCategory == null;
            final color = isActive
                ? const Color(AppColors.primary)
                : const Color(0xFF6B717C);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_CreditTabSelectionResult.tab(tab)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          tab.iconPath,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tab.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(AppColors.black),
                            ),
                          ),
                        ),
                        if (isActive)
                          const Icon(
                            Icons.check,
                            color: Color(AppColors.primary),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          BlocBuilder<ObjectTypeBloc, ObjectTypeState>(
            builder: (context, state) {
              if (state is ObjectTypeLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (state is ObjectTypeError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    state.message,
                    style: AppStyle.manrope(
                      size: 14,
                      weight: FontWeight.w400,
                      color: const Color(AppColors.red),
                    ),
                  ),
                );
              }
              if (state is ObjectTypeLoaded) {
                final categories = state.objectTypes
                    .where(
                      (type) => type.entityType.toLowerCase() == 'credittab',
                    )
                    .toList();
                if (categories.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Категории не найдены',
                      style: AppStyle.manrope(
                        size: 14,
                        weight: FontWeight.w400,
                        color: const Color(0xFF6B717C),
                      ),
                    ),
                  );
                }
                return Column(
                  children: categories.map((category) {
                    final bool isActive = selectedCategory?.id == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(
                            context,
                          ).pop(_CreditTabSelectionResult.category(category)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.label_outline,
                                  size: 20,
                                  color: Color(0xFF6B717C),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(AppColors.black),
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  const Icon(
                                    Icons.check,
                                    color: Color(AppColors.primary),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _CreditList extends StatefulWidget {
  final List<CreditModel> credits;
  final int currentPage;
  final int totalPages;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onLoadMore;
  final ValueChanged<int> onFavouriteToggle;

  const _CreditList({
    required this.credits,
    required this.currentPage,
    required this.totalPages,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onFavouriteToggle,
  });

  @override
  State<_CreditList> createState() => _CreditListState();
}

class _CreditListState extends State<_CreditList> {
  bool _isRequestingMore = false;

  bool get _canLoadMore =>
      !_isRequestingMore && widget.currentPage < widget.totalPages;

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 100 &&
        _canLoadMore) {
      _isRequestingMore = true;
      widget.onLoadMore(widget.currentPage + 1);
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant _CreditList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _isRequestingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Refresher(
        onRefresh: widget.onRefresh,
        content: ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: widget.credits.length + (_isRequestingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= widget.credits.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final credit = widget.credits[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CreditCardWidget(
                credit: credit,
                onFavouriteToggle: () => widget.onFavouriteToggle(credit.id),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CreditTabSelectionResult {
  final CreditTab? tab;
  final ObjectTypeModel? category;

  const _CreditTabSelectionResult._({this.tab, this.category});

  const _CreditTabSelectionResult.tab(CreditTab tab)
    : this._(tab: tab, category: null);

  const _CreditTabSelectionResult.category(ObjectTypeModel category)
    : this._(tab: null, category: category);
}

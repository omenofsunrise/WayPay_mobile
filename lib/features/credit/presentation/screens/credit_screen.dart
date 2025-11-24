import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/buttons/add_button.dart';
import 'package:waypay_mobile/core/widgets/cards/credit_card.dart';
import 'package:waypay_mobile/core/widgets/filters/filter_components.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/pagination_widget.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_state.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_filters_sheet.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_tab.dart';
import 'package:waypay_mobile/features/objectType/presentation/block/object_type_bloc.dart';
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
      creditTypeId: filters?.creditTypeId,
      page: page,
    );
  }

  bool _hasFilterValues(GetCreditsQuery? query) {
    if (query == null) return false;
    return query.creditId != null ||
        query.dateFrom != null ||
        query.dateTo != null ||
        (query.investorNickname != null &&
            query.investorNickname!.isNotEmpty) ||
        (query.clientFullname != null && query.clientFullname!.isNotEmpty) ||
        query.creditTypeId != null;
  }

  void _clearFilters() {
    if (!_hasFilterValues(_appliedFilters)) return;
    setState(() => _appliedFilters = null);
    _loadCredits();
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
      setState(() {
        _appliedFilters = _hasFilterValues(result) ? result : null;
      });
      _loadCredits();
    }
  }

  Future<void> _openCreditTabSheet() async {
    final selected = await showModalBottomSheet<CreditTab>(
      context: context,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withOpacity(0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreditTabSheet(selectedTab: _selectedTab),
    );

    if (selected != null && selected != _selectedTab) {
      setState(() => _selectedTab = selected);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: BlocBuilder<CreditBloc, CreditState>(
                      builder: (context, state) {
                        if (state is CreditLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is CreditError) {
                          return Center(
                            child: Text('Ошибка: ${state.message}'),
                          );
                        }
                        if (state is CreditLoaded) {
                          if (state.credits.isEmpty) {
                            return const Center(
                              child: Text('Договоры не найдены'),
                            );
                          }
                          return Column(
                            children: [
                              Expanded(
                                child: Refresher(
                                  onRefresh: () async => _loadCredits(),
                                  content: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    itemCount: state.credits.length,
                                    itemBuilder: (context, index) {
                                      final credit = state.credits[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: CreditCardWidget(
                                          credit: credit,
                                          onFavouriteToggle: () {
                                            context.read<CreditBloc>().add(
                                              ToggleFavouriteEvent(
                                                creditId: credit.id,
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: PaginationWidget(
                                  currentPage: state.currentPage,
                                  totalPages: state.totalPages,
                                  onPageSelected: (page) {
                                    _loadCredits(page: page);
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasCustomTab = _selectedTab != CreditTab.all;
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
          iconAsset: _selectedTab.iconPath,
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
  const _CreditTabSheet({required this.selectedTab});

  final CreditTab selectedTab;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length * 2 - 1, (index) {
          if (index.isOdd) return const SizedBox(height: 4);
          final tab = tabs[index ~/ 2];
          final isActive = tab == selectedTab;
          final color = isActive
              ? const Color(AppColors.primary)
              : const Color(0xFF6B717C);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(tab),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(AppColors.black),
                        ),
                      ),
                    ),
                    if (isActive)
                      const Icon(Icons.check, color: Color(AppColors.primary)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

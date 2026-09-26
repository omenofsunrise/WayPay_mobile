import 'package:waypay_mobile/assets/resources.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/storage/user_storage.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_card.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_filters_sheet.dart';
import 'package:waypay_mobile/features/credit/presentation/widgets/credit_tab.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';

import 'package:waypay_mobile/features/credit/data/models/credit_model.dart';
import 'package:waypay_mobile/features/credit/data/models/get_query_credits.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_event.dart';
import 'package:waypay_mobile/features/credit/presentation/bloc/credit_state.dart';
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
  GetCreditsQuery? _filters;

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
    final parsed = _parseSearch(trimmedSearch);

    final f = _filters;

    return GetCreditsQuery(
      creditId: parsed.creditId,
      clientFullname: parsed.clientFullname ?? f?.clientFullname,
      search: null,
      page: page,
      // Значения из листа фильтров приоритетнее вкладки: вкладка задаёт
      // только то, что пользователь не выбрал вручную.
      isFavourite:
          f?.isFavourite ??
          (_selectedTab == CreditTab.favourite ? true : null),
      isActive: f?.isActive ?? (_selectedTab == CreditTab.archived ? false : null),
      debt: f?.debt ?? (_selectedTab == CreditTab.debtors ? true : null),
      name: f?.name,
      investorNickname: f?.investorNickname,
      clientAddress: f?.clientAddress,
      dateFrom: f?.dateFrom,
      dateTo: f?.dateTo,
      createdAt: f?.createdAt,
      createdTo: f?.createdTo,
      creditTypeId: f?.creditTypeId,
      inDebt: f?.inDebt,
      terminated: f?.terminated,
      myCredits: f?.myCredits,
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<GetCreditsQuery>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreditFiltersSheet(initialFilters: _filters),
    );

    if (result == null) return;
    setState(() => _filters = result);
    _loadCredits();
  }

  void _resetFilters() {
    setState(() => _filters = null);
    _loadCredits();
  }

  bool get _hasFilters {
    final f = _filters;
    if (f == null) return false;
    return f.toQueryParams().keys.any((k) => k != 'page' && k != 'pageSize');
  }

  void _onTabSelected(CreditTab tab) {
    if (tab == _selectedTab) return;
    setState(() => _selectedTab = tab);
    _loadCredits();
  }

  _ParsedSearch _parseSearch(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const _ParsedSearch();
    }
    final trimmed = value.trim();
    final digits = trimmed.replaceAll(RegExp(r'\\D'), '');
    final hasLetters = RegExp(r'[A-Za-zА-Яа-я]').hasMatch(trimmed);
    if (digits.isNotEmpty && !hasLetters) {
      return _ParsedSearch(creditId: int.tryParse(digits));
    }
    return _ParsedSearch(clientFullname: trimmed);
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
                    onLoadMore: (page) =>
                        _loadCredits(refresh: false, page: page),
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
    return Row(
      children: [
        Expanded(
          child: SearchField(
            controller: _searchController,
            hintText: 'Поиск по № договора или ФИО',
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchChanged,
          ),
        ),
        const SizedBox(width: 8),
        _buildFiltersButton(),
        const SizedBox(width: 8),
        CreditTabDropdown(
          selectedTab: _selectedTab,
          onTabSelected: _onTabSelected,
        ),
      ],
    );
  }

  Widget _buildFiltersButton() {
    final active = _hasFilters;
    return GestureDetector(
      onTap: _openFilters,
      onLongPress: active ? _resetFilters : null,
      child: SizedBox(
        height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? const Color(0x1A18A0A5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? const Color(AppColors.primary)
                  : Color(AppColors.borderColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  SvgIcons.filter,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    active
                        ? const Color(AppColors.primary)
                        : const Color(0xFF6B717C),
                    BlendMode.srcIn,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(AppColors.primary),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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

class _ParsedSearch {
  final int? creditId;
  final String? clientFullname;

  const _ParsedSearch({this.creditId, this.clientFullname});
}

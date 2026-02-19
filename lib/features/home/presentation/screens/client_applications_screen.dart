import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:waypay_styles/waypay_styles.dart';
import 'package:waypay_mobile/core/utils/bottom_nav_controller.dart';

import 'package:waypay_mobile/features/home/data/models/credit_applications/credit_application_model.dart';
import 'package:waypay_mobile/features/home/domain/entities/client_application_filters.dart';
import 'package:waypay_mobile/features/home/presentation/cubit/client_applications/client_applications_cubit.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/client_application_card.dart';
import 'package:waypay_mobile/features/home/presentation/widgets/client_applications_filters.dart';
import 'package:waypay_mobile/routes/routes.dart';

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
  Timer? _debounce;
  bool _showSearchHint = false;
  ClientApplicationFilters? _appliedFilters;
  String _lastSubmittedQuery = '';

  static const _searchDelay = Duration(milliseconds: 400);

  ClientApplicationsTab get _currentTab => _tabController.index == 0
      ? ClientApplicationsTab.all
      : ClientApplicationsTab.mine;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentTab(query: '');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final cubit = context.read<ClientApplicationsCubit>();
    final tabState = _currentTab == ClientApplicationsTab.all
        ? cubit.state.allTab
        : cubit.state.myTab;
    if (!tabState.initialized) {
      _loadCurrentTab();
    }
  }

  String _normalizeDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

  void _onSearchChanged(String raw) {
    _debounce?.cancel();
    final query = raw.trim();
    final digits = _normalizeDigits(query);
    final hasQuery = query.isNotEmpty;
    final meetsPhoneRequirement = digits.length >= 11;
    final meetsNameRequirement = query.length >= 4;
    final shouldSearch =
        hasQuery && (meetsPhoneRequirement || meetsNameRequirement);

    setState(() => _showSearchHint = hasQuery && !shouldSearch);

    if (!hasQuery) {
      _lastSubmittedQuery = '';
      _loadCurrentTab(query: '');
      return;
    }

    if (!shouldSearch) {
      return;
    }

    _debounce = Timer(_searchDelay, () {
      if (!mounted) return;
      _lastSubmittedQuery = query;
      _loadCurrentTab(query: query);
    });
  }

  Future<void> _loadCurrentTab({
    String? query,
    ClientApplicationFilters? filters,
    bool replaceFilters = false,
  }) {
    return _loadTab(
      tab: _currentTab,
      query: query,
      filters: filters,
      replaceFilters: replaceFilters,
    );
  }

  Future<void> _loadTab({
    required ClientApplicationsTab tab,
    String? query,
    ClientApplicationFilters? filters,
    bool replaceFilters = false,
  }) {
    return context.read<ClientApplicationsCubit>().loadApplications(
      tab: tab,
      query: query ?? _lastSubmittedQuery,
      filters: filters ?? _appliedFilters,
      replaceFilters: replaceFilters,
    );
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
          ClientApplicationsFiltersSheet(initialFilters: _appliedFilters),
    );
    BottomNavController.instance.show();
    if (result != null) {
      final applied = result.isEmpty ? null : result;
      setState(() {
        _appliedFilters = applied;
      });
      await _loadCurrentTab(filters: applied, replaceFilters: true);
    }
  }

  Future<void> _clearAppliedFilters() async {
    setState(() => _appliedFilters = null);
    await _loadCurrentTab(filters: null, replaceFilters: true);
  }

  void _openDetails(CreditApplicationModel application) {
    context.pushNamed(
      Routes.clientApplicationDetailScreen.toName,
      extra: application,
    );
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
              const Header(
                title: 'Заявки',
                showBackButton: true,
                showNotifications: false,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _searchController,
                      hintText: 'Поиск',
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterButton(
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
                      color: Color(AppColors.uiBorder),
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
                child:
                    BlocBuilder<
                      ClientApplicationsCubit,
                      ClientApplicationsState
                    >(
                      builder: (context, state) {
                        return TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _ApplicationsTabContent(
                              data: state.allTab,
                              onRetry: () =>
                                  _loadTab(tab: ClientApplicationsTab.all),
                              onApplicationTap: _openDetails,
                            ),
                            _ApplicationsTabContent(
                              data: state.myTab,
                              onRetry: () =>
                                  _loadTab(tab: ClientApplicationsTab.mine),
                              onApplicationTap: _openDetails,
                            ),
                          ],
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationsTabContent extends StatelessWidget {
  const _ApplicationsTabContent({
    required this.data,
    required this.onRetry,
    required this.onApplicationTap,
  });

  final ClientApplicationsTabData data;
  final Future<void> Function() onRetry;
  final void Function(CreditApplicationModel) onApplicationTap;

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  String _formatCurrency(double? value) {
    if (value == null) return '—';
    return _currencyFormat.format(value);
  }

  String _formatTerm(int? months) {
    if (months == null || months <= 0) return '—';
    return '$months мес.';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return _dateFormat.format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (data.isLoading && data.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.error != null) {
      return _ErrorView(message: data.error!, onRetry: onRetry);
    }

    if (data.items.isEmpty) {
      return const _EmptyApplicationsView();
    }

    return RefreshIndicator(
      color: const Color(AppColors.primary),
      onRefresh: onRetry,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        itemCount: data.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final application = data.items[index];
          final amountValue =
              application.productPrice ?? application.totalAmount;

          return ClientApplicationCard(
            fullName: application.fullName ?? '—',
            applicationNumber:
                application.applicationNumber ?? '№ ${application.id}',
            term: _formatTerm(application.termMonths),
            productName: application.productName ?? '—',
            amount: _formatCurrency(amountValue),
            onTap: () => onApplicationTap(application),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 15),
            ),
            const SizedBox(height: 12),
            DefaultButton(
              text: 'Повторить',
              onPressed: () => onRetry(),
              color: const Color(AppColors.primary),
              textColor: Colors.white,
            ),
          ],
        ),
      ),
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
            color: Color(AppColors.uiBorder),
          ),
          SizedBox(height: 12),
          Text(
            'Нет заявок по текущим фильтрам',
            style: TextStyle(
              fontSize: 15,
              color: Color(AppColors.uiBorder),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

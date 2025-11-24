import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_mobile/core/network/token_storage.dart';
import 'package:waypay_mobile/core/theme/app_colors.dart';
import 'package:waypay_mobile/core/widgets/filters/filter_components.dart';
import 'package:waypay_mobile/core/widgets/header.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/core/widgets/search_field.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';
import 'package:waypay_mobile/features/payment/data/models/schedule/schedule_model.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/schedule/schedule_bloc.dart';
import 'package:waypay_mobile/features/payment/presentation/models/payment_sort_option.dart';
import 'package:waypay_mobile/features/payment/presentation/models/schedule_filters.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/payment_preview_card.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/schedule_filters_sheet.dart';
import 'package:waypay_mobile/routes/routes.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _searchController = TextEditingController();
  final _tokenStorage = TokenStorage();
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  String _searchQuery = '';
  Timer? _debounce;
  ScheduleFilters? _appliedFilters;
  late PaymentSortOption _currentSort;

  @override
  void initState() {
    super.initState();
    _currentSort = paymentSortOptions.first;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSchedules(refresh: true, page: 1);
    });
  }

  Future<void> _logout() async {
    await _tokenStorage.clearAll();
    if (mounted) {
      context.pushReplacementNamed(Routes.phoneAuthScreen.toName);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    final bloc = context.read<ScheduleBloc>();
    final state = bloc.state;
    if (state is ScheduleLoaded && state.hasMoreData) {
      _isLoadingMore = true;
      _loadSchedules(page: state.currentPage + 1);
    }
  }

  void _loadSchedules({bool refresh = false, int? page}) {
    final filters = _appliedFilters;
    final sort = _currentSort;
    context.read<ScheduleBloc>().add(
      LoadSchedule(
        refresh: refresh,
        page: page,
        pageSize: 10,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: sort.sortBy,
        sortDirection: sort.sortDirection,
        clientName: filters?.clientFullName,
        investorNickname: filters?.investor,
        creditId: filters?.contractNumber,
        dateFrom: filters?.dateFromIso,
        dateTo: filters?.dateToIso,
      ),
    );
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = query;
      _loadSchedules(refresh: true, page: 1);
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ScheduleFilters>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withOpacity(0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ScheduleFiltersSheet(initialFilters: _appliedFilters),
    );

    if (result != null) {
      final applied = result.isEmpty ? null : result;
      setState(() => _appliedFilters = applied);
      _loadSchedules(refresh: true, page: 1);
    }
  }

  Future<void> _openSortSheet() async {
    final result = await showModalBottomSheet<PaymentSortOption>(
      context: context,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withOpacity(0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ScheduleSortSheet(
        options: paymentSortOptions,
        selected: _currentSort,
      ),
    );

    if (result != null && result != _currentSort) {
      setState(() => _currentSort = result);
      _loadSchedules(refresh: true, page: 1);
    }
  }

  void _openPaymentDetail(ScheduleModel schedule) {
    context.pushNamed(Routes.paymentDetailScreen.toName, extra: schedule);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: BlocListener<ScheduleBloc, ScheduleState>(
            listener: (context, state) {
              if (state is ScheduleLoaded || state is ScheduleError) {
                _isLoadingMore = false;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(
                  title: 'Ожидаемые платежи',
                  showBackButton: true,
                  showNotifications: true,
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocBuilder<ScheduleBloc, ScheduleState>(
                    builder: (context, state) {
                      if (state is ScheduleInitial) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ScheduleError) {
                        return _buildErrorState(state.message);
                      }
                      if (state is ScheduleLoaded) {
                        if (state.schedules.isEmpty) {
                          return const Center(
                            child: Text(
                              'Нет ожидаемых платежей',
                              style: TextStyle(
                                color: Color(AppColors.darkGrey),
                              ),
                            ),
                          );
                        }
                        return Refresher(
                          onRefresh: () async {
                            _loadSchedules(refresh: true, page: 1);
                          },
                          content: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 32),
                            itemCount:
                                state.schedules.length +
                                (_isLoadingMore && state.hasMoreData ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index >= state.schedules.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final schedule = state.schedules[index];
                              return PaymentPreviewCard(
                                payment: _scheduleToPayment(schedule),
                                onTap: () => _openPaymentDetail(schedule),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final bool hasCustomSort = _currentSort != paymentSortOptions.first;
    return Row(
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
          onTap: _openSortSheet,
          isActive: hasCustomSort,
          iconAsset: SvgIcons.sort,
        ),
        const SizedBox(width: 12),
        FilterButton(onTap: _openFilters, isActive: _appliedFilters != null),
      ],
    );
  }

  PaymentItemModel _scheduleToPayment(ScheduleModel schedule) {
    return PaymentItemModel(
      id: schedule.id,
      creditId: schedule.creditId,
      paymentAmount: schedule.paymentAmount,
      paymentDate: schedule.paymentDate,
      type: PaymentType.cash,
      accepted: false,
      clientFullName: schedule.clientName,
      investorNickname: null,
      employeeFullName: null,
      income: 0,
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (message.contains('Сессия')) {
                  _logout();
                } else {
                  _loadSchedules(refresh: true, page: 1);
                }
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSortSheet extends StatelessWidget {
  const _ScheduleSortSheet({required this.options, required this.selected});

  final List<PaymentSortOption> options;
  final PaymentSortOption selected;

  @override
  Widget build(BuildContext context) {
    return FilterSheet(
      title: 'Сортировка',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length * 2 - 1, (index) {
          if (index.isOdd) return const SizedBox(height: 4);
          final option = options[index ~/ 2];
          final isActive = option == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(option),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? const Color(AppColors.primary)
                              : const Color(AppColors.black),
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

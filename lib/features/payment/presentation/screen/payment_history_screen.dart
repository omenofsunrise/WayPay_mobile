import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_mobile/assets/resources.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/core/widgets/refresh.dart';
import 'package:waypay_mobile/features/payment/data/models/expected/payment_item_model.dart';
import 'package:waypay_mobile/features/payment/presentation/bloc/expected/payment_bloc.dart';
import 'package:waypay_mobile/features/payment/presentation/models/payment_history_filters.dart';
import 'package:waypay_mobile/features/payment/presentation/models/payment_sort_option.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/payment_history_filters_sheet.dart';
import 'package:waypay_mobile/features/payment/presentation/widgets/payment_preview_card.dart';
import 'package:waypay_mobile/routes/routes.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  String _searchQuery = '';
  Timer? _debounce;
  PaymentHistoryFilters? _appliedFilters;
  late PaymentSortOption _currentSort;

  @override
  void initState() {
    super.initState();
    _currentSort = paymentSortOptions.first;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments(refresh: true, page: 1);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
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
    final bloc = context.read<PaymentBloc>();
    final state = bloc.state;
    if (state is PaymentLoaded && state.hasMoreData) {
      _isLoadingMore = true;
      _loadPayments(page: state.currentPage + 1);
    }
  }

  void _loadPayments({bool refresh = false, int? page}) {
    final filters = _appliedFilters;
    final sort = _currentSort;
    context.read<PaymentBloc>().add(
      LoadPayment(
        refresh: refresh,
        page: page,
        pageSize: 10,
        sortBy: sort.sortBy,
        descending: sort.sortDirection == 'desc',
        search: _searchQuery.isEmpty ? null : _searchQuery,
        investorNickname: filters?.investor,
        dateFrom: filters?.dateFrom,
        dateTo: filters?.dateTo,
        confirmed: filters?.confirmed,
      ),
    );
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = query;
      _loadPayments(refresh: true, page: 1);
    });
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<PaymentHistoryFilters>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withValues(alpha: 0.7),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          PaymentHistoryFiltersSheet(initialFilters: _appliedFilters),
    );

    if (result != null) {
      final applied = result.isEmpty ? null : result;
      setState(() => _appliedFilters = applied);
      _loadPayments(refresh: true, page: 1);
    }
  }

  Future<void> _openSortSheet() async {
    final result = await showModalBottomSheet<PaymentSortOption>(
      context: context,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.white.withValues(alpha: 0.7),
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
      _loadPayments(refresh: true, page: 1);
    }
  }

  void _openPaymentDetail(PaymentItemModel payment) {
    context.pushNamed(Routes.paymentDetailScreen.toName, extra: payment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: BlocListener<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentLoaded || state is PaymentError) {
                _isLoadingMore = false;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(
                  title: 'История платежей',
                  showBackButton: true,
                  showNotifications: false,
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocBuilder<PaymentBloc, PaymentState>(
                    builder: (context, state) {
                      if (state is PaymentInitial) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is PaymentError) {
                        return _buildErrorState(state.message);
                      }
                      if (state is PaymentLoaded) {
                        if (state.payment.isEmpty) {
                          return const Center(
                            child: Text(
                              'История платежей пуста',
                              style: TextStyle(
                                color: Color(AppColors.uiBorder),
                              ),
                            ),
                          );
                        }
                        return Refresher(
                          onRefresh: () async {
                            _loadPayments(refresh: true, page: 1);
                          },
                          content: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 32),
                            itemCount:
                                state.payment.length +
                                (_isLoadingMore && state.hasMoreData ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index >= state.payment.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final payment = state.payment[index];
                              return PaymentPreviewCard(
                                payment: payment,
                                showStatus: true,
                                onTap: () => _openPaymentDetail(payment),
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
                _loadPayments(refresh: true, page: 1);
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

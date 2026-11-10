import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';
import 'package:waypay_mobile/features/investors/data/models/investor_pool_model.dart';
import 'package:waypay_mobile/features/investors/data/models/investors_model.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investor_pool_bloc.dart';
import 'package:waypay_mobile/features/investors/presentation/bloc/investors_bloc.dart';

class InvestorPickerResult {
  const InvestorPickerResult.investor(this.investor) : pool = null;
  const InvestorPickerResult.pool(this.pool) : investor = null;

  final InvestorsModel? investor;
  final InvestorPoolModel? pool;
}

class InvestorPickerModal extends StatefulWidget {
  const InvestorPickerModal({
    super.key,
    this.includeInvestor = true,
    this.includePool = true,
    this.title = 'Выбор инвестора/пула',
  }) : assert(
         includeInvestor || includePool,
         'Хотя бы один тип должен быть доступен',
       );

  final bool includeInvestor;
  final bool includePool;
  final String title;

  @override
  State<InvestorPickerModal> createState() => _InvestorPickerModalState();
}

class _InvestorTile extends StatelessWidget {
  const _InvestorTile({
    required this.name,
    required this.cashText,
    required this.contractText,
    required this.onTap,
  });

  final String name;
  final String cashText;
  final String contractText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WayPayEntityTile(
      title: name,
      subtitle: 'Договор до $contractText',
      trailing: Text(
        cashText,
        style: AppStyle.manrope(size: 14, weight: FontWeight.w600),
      ),
      showChevron: true,
      onTap: onTap,
    );
  }
}

class _InvestorPickerModalState extends State<InvestorPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearchHint = false;
  bool _hasValidSearch = false;
  String _lastSubmittedQuery = '';

  static const _searchDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    context.read<InvestorsBloc>().add(
      LoadInvestorsEvent(refresh: true, page: 1, pageSize: 10),
    );
    if (widget.includePool) {
      context.read<InvestorPoolBloc>().add(
        LoadInvestorPool(refresh: true, page: 1, pageSize: 10),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final raw = _searchController.text;
    _debounce?.cancel();

    final query = raw.trim();

    if (query.isEmpty) {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = false;
      });
      context.read<InvestorsBloc>().add(ResetSearchInvestorsEvent());
      if (widget.includePool) {
        context.read<InvestorPoolBloc>().add(ResetInvestorPool());
      }
      return;
    }

    final meetsRequirement = query.isNotEmpty;

    if (meetsRequirement) {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = true;
      });
      _debounce = Timer(_searchDelay, () {
        if (!mounted) return;
        _lastSubmittedQuery = query;
        context.read<InvestorsBloc>().add(SearchInvestorsEvent(query));
        if (widget.includePool) {
          context.read<InvestorPoolBloc>().add(SearchInvestorPool(query));
        }
      });
    } else {
      setState(() {
        _showSearchHint = false;
        _hasValidSearch = false;
      });
    }
  }

  void _retryLastSearch() {
    if (_lastSubmittedQuery.isEmpty) {
      context.read<InvestorsBloc>().add(
        LoadInvestorsEvent(refresh: true, page: 1, pageSize: 10),
      );
      if (widget.includePool) {
        context.read<InvestorPoolBloc>().add(
          LoadInvestorPool(refresh: true, page: 1, pageSize: 10),
        );
      }
      return;
    }
    context.read<InvestorsBloc>().add(
      SearchInvestorsEvent(_lastSubmittedQuery),
    );
    if (widget.includePool) {
      context.read<InvestorPoolBloc>().add(
        SearchInvestorPool(_lastSubmittedQuery),
      );
    }
  }

  String _formatCash(double? value) {
    if (value == null) return '—';
    final formatter = NumberFormat.decimalPattern('ru');
    return '${formatter.format(value.round())}₽';
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  List<InvestorsModel> _extractInvestors(InvestorsState state) {
    if (!widget.includeInvestor) return [];
    if (state is InvestorsLoaded) return state.investors;
    return [];
  }

  List<InvestorPoolModel> _extractPools(InvestorPoolState state) {
    if (!widget.includePool) return [];
    if (state is InvestorPoolLoaded) return state.items;
    return [];
  }

  Widget _buildResults(
    InvestorsState investorsState,
    InvestorPoolState poolState,
  ) {
    final investors = _extractInvestors(investorsState);
    final pools = _extractPools(poolState);
    final hasData = investors.isNotEmpty || pools.isNotEmpty;

    if (!hasData) {
      final isLoading =
          investorsState is InvestorsLoading ||
          poolState is InvestorPoolLoading;
      if (isLoading) {
        return const WayPayLoadingState();
      }
      if (investorsState is InvestorsError && poolState is InvestorPoolError) {
        return WayPayErrorState(
          message: 'Ошибка загрузки списка.',
          onRetry: _retryLastSearch,
        );
      }
      if (investorsState is InvestorsError && !widget.includePool) {
        return WayPayErrorState(
          message: investorsState.message,
          onRetry: _retryLastSearch,
        );
      }
      if (poolState is InvestorPoolError && !widget.includeInvestor) {
        return WayPayErrorState(
          message: poolState.message,
          onRetry: _retryLastSearch,
        );
      }
      return WayPayEmptyState(
        title: widget.includePool
            ? 'Инвесторы и пулы не найдены'
            : 'Инвесторы не найдены',
      );
    }

    if (!_hasValidSearch) {
      if (_searchController.text.trim().isEmpty) {
        return _buildCombinedList(investors, pools);
      }
      return const SizedBox.shrink();
    }

    if (investorsState is InvestorsError && poolState is InvestorPoolError) {
      return WayPayErrorState(
        message: 'Ошибка загрузки списка.',
        onRetry: _retryLastSearch,
      );
    }

    return _buildCombinedList(investors, pools);
  }

  Widget _buildCombinedList(
    List<InvestorsModel> investors,
    List<InvestorPoolModel> pools,
  ) {
    final items = <Widget>[];
    for (final investor in investors) {
      items.add(
        _InvestorTile(
          name: investor.nickname,
          cashText: _formatCash(investor.cashbox),
          contractText: _formatDateShort(investor.contractEndDate),
          onTap: () => Navigator.of(
            context,
          ).pop(InvestorPickerResult.investor(investor)),
        ),
      );
    }
    for (final pool in pools) {
      final date = pool.activeUntil ?? pool.createdAt;
      items.add(
        _InvestorTile(
          name: pool.name,
          cashText: _formatCash(pool.balance),
          contractText: _formatDateShort(date),
          onTap: () =>
              Navigator.of(context).pop(InvestorPickerResult.pool(pool)),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 16, color: Color(0xFFE5E5EA)),
      itemBuilder: (_, index) => items[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WayPayBottomSheet(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchField(
            controller: _searchController,
            hintText: 'Поиск',
            onChanged: (_) => _onSearchChanged(),
          ),
          if (_showSearchHint)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Введите имя или номер телефона для поиска',
                  style: AppStyle.manrope(
                    size: 14,
                    weight: FontWeight.w400,
                    color: const Color(AppColors.uiBorder),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: BlocBuilder<InvestorsBloc, InvestorsState>(
              builder: (context, investorsState) {
                return BlocBuilder<InvestorPoolBloc, InvestorPoolState>(
                  builder: (context, poolState) =>
                      _buildResults(investorsState, poolState),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          DefaultButton(
            text: 'Создать нового инвестора',
            isPrimary: true,
            showIcon: true,
            icon: Icons.add,
            onPressed: () {
              // TODO: Реализовать создание нового инвестора
            },
          ),
        ],
      ),
    );
  }
}
